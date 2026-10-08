import assert from 'node:assert/strict';
import fs from 'node:fs';
import {webcrypto} from 'node:crypto';
globalThis.crypto ??= webcrypto;
const source = fs.readFileSync(new URL('../../web/usp_native_operate.js', import.meta.url), 'utf8');
const {encodeOperate,decodeOperate,nativeOperate,installNativeOperate} = await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
const fixture = JSON.parse(fs.readFileSync(new URL('./usp_native_operate_fixture.json',import.meta.url)));
const {command,args,messageId,commandKey} = fixture;
const request=Buffer.from(fixture.request,'base64'), response=Buffer.from(fixture.response,'base64');
assert.deepEqual(Buffer.from(encodeOperate(command,args,messageId,commandKey)),request);
const result=decodeOperate(response,command,messageId,commandKey);
assert.equal(JSON.parse(result.outputArgs.Result).cancelled,true);
assert.equal(result.commandKey,commandKey);
assert.throws(()=>decodeOperate(response,command,'wrong',commandKey),/ID mismatch/);
assert.throws(()=>decodeOperate(response,'wrong',messageId,commandKey),/command mismatch/);
assert.throws(()=>decodeOperate(response.subarray(0,-1),command,messageId,commandKey),/Truncated/);
assert.throws(()=>encodeOperate('Device.Reboot()',{},messageId,commandKey),/Unsupported/);
assert.throws(()=>encodeOperate(command,{Settings:5},messageId,commandKey),/Invalid/);
// USP Error.err_code and OperateResp.CommandFailure.err_code are fixed32.
// These wire fixtures exercise little-endian unsigned decoding, including views
// with a nonzero byte offset and an incomplete fixed32 field inside a full frame.
function lengthDelimited(number, bytes) {
  const size = [];
  let remaining = bytes.length;
  do {
    size.push((remaining & 127) | (remaining > 127 ? 128 : 0));
    remaining = Math.floor(remaining / 128);
  } while (remaining);
  return Buffer.concat([Buffer.from([number * 8 + 2, ...size]), bytes]);
}
function errorResponse(codeField, commandFailure) {
  const message = Buffer.from('Synthetic refusal');
  const error = Buffer.concat([lengthDelimited(2, message), codeField]);
  const body = commandFailure
    ? lengthDelimited(2, lengthDelimited(7, lengthDelimited(1, Buffer.concat([
      lengthDelimited(1, Buffer.from(command)), lengthDelimited(4, error),
    ]))))
    : lengthDelimited(3, error);
  return Buffer.concat([
    lengthDelimited(1, Buffer.concat([
      lengthDelimited(1, Buffer.from(messageId)),
      Buffer.from([16, commandFailure ? 7 : 0]),
    ])),
    lengthDelimited(2, body),
  ]);
}
for (const [code, bytes] of [
  [7004, [0x0d, 0x5c, 0x1b, 0x00, 0x00]],
  [4294967295, [0x0d, 0xff, 0xff, 0xff, 0xff]],
]) {
  for (const commandFailure of [false, true]) {
    const packet = errorResponse(Buffer.from(bytes), commandFailure);
    const view = Buffer.concat([Buffer.from([0xaa, 0xbb]), packet]).subarray(2);
    assert.throws(() => decodeOperate(view, command, messageId, commandKey), error => {
      assert.equal(typeof error, 'string');
      assert.equal(error, `Operate failed: ${commandFailure ? 'Operation' : 'Protocol'} error: Synthetic refusal (code: ${code})`);
      return true;
    });
  }
}
for (const commandFailure of [false, true]) {
  const packet = errorResponse(Buffer.from([0x0d, 0x5c, 0x1b, 0x00]), commandFailure);
  assert.throws(() => decodeOperate(packet, command, messageId, commandKey),
    /Truncated USP field/);
}

let calls=0;
const client={baseUrl:()=> 'https://router.example',getToken:()=> 'synthetic-token'};
await assert.rejects(nativeOperate(client,command,args,async()=>{calls++;throw new Error('reply lost');}),/reply lost/);
assert.equal(calls,1);
await assert.rejects(nativeOperate({...client,getToken:()=>null},command,args,async()=>{calls++;}),/Authentication/);
assert.equal(calls,1);

// Shared with the Dart parser/mapping tests: these are the exact rejection
// values crossing the JS Promise boundary, not Error.message approximations.
const errors = JSON.parse(fs.readFileSync(new URL('./usp_native_operate_errors.json', import.meta.url)));
const cryptoDescriptor = Object.getOwnPropertyDescriptor(globalThis, 'crypto');
Object.defineProperty(globalThis, 'crypto', {value: {randomUUID: () => messageId}, configurable: true});
try {
  for (const testCase of errors) {
    let dispatches = 0;
    const fetcher = async () => {
      dispatches++;
      switch (testCase.kind) {
        case 'network': throw new TypeError(testCase.message);
        case 'timeout': throw new DOMException('Synthetic timeout', 'TimeoutError');
        case 'http': return {ok: false, status: testCase.status};
        case 'body': return {ok: true, arrayBuffer: async () => {throw new TypeError(testCase.message);}};
        case 'protocol':
        case 'command': {
          const code = Buffer.alloc(5);
          code[0] = 0x0d;
          code.writeUInt32LE(testCase.faultCode, 1);
          return {ok: true, arrayBuffer: async () => errorResponse(code, testCase.kind === 'command')};
        }
        case 'malformed': return {ok: true, arrayBuffer: async () => new Uint8Array()};
        default: throw new Error('Unexpected dispatch');
      }
    };
    const errorClient = testCase.kind === 'auth' ? {...client, getToken: () => null} : client;
    const errorArgs = testCase.kind === 'validation' ? {Settings: 5} : args;
    await assert.rejects(nativeOperate(errorClient, command, errorArgs, fetcher), error => {
      assert.equal(typeof error, 'string', testCase.name);
      assert.equal(error, testCase.error, testCase.name);
      return true;
    });
    assert.equal(dispatches, ['auth', 'validation'].includes(testCase.kind) ? 0 : 1, testCase.name);
  }
} finally {
  Object.defineProperty(globalThis, 'crypto', cryptoDescriptor);
}
class Original {operate(...args){return args;}}
installNativeOperate(Original);
assert.deepEqual(new Original().operate('Device.Reboot()',{}),['Device.Reboot()',{}]);
console.log('PASS: operation fixtures, canonical error contract, single dispatch, and original command routing');
