import assert from 'node:assert/strict';
import fs from 'node:fs';
import {webcrypto} from 'node:crypto';
import {test} from 'node:test';

globalThis.crypto ??= webcrypto;
const source = fs.readFileSync(new URL('../../web/usp_client.js', import.meta.url), 'utf8');
const {default: init, UspClientBuilder} = await import(
  `data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
await init({module_or_path: fs.readFileSync(new URL('../../web/usp_client_bg.wasm', import.meta.url))});
const fixture = JSON.parse(fs.readFileSync(new URL('./usp_operate_fixture.json', import.meta.url)));
const encoder = new TextEncoder();
const decoder = new TextDecoder();
const secret = 'synthetic-private-operation-value';

// These helpers inspect mocked requests and construct protocol fixtures only.
function varint(value) {
  const bytes = [];
  do {
    bytes.push((value & 127) | (value > 127 ? 128 : 0));
    value = Math.floor(value / 128);
  } while (value);
  return Buffer.from(bytes);
}
function field(number, value) {
  const bytes = typeof value === 'string' ? encoder.encode(value) : value;
  return Buffer.concat([varint(number * 8 + 2), varint(bytes.length), bytes]);
}
function fixed32(number, value) {
  const bytes = Buffer.alloc(4);
  bytes.writeUInt32LE(value);
  return Buffer.concat([varint(number * 8 + 5), bytes]);
}
function fields(bytes) {
  let offset = 0;
  function integer() {
    let value = 0;
    for (let shift = 0; shift < 49; shift += 7) {
      assert.ok(offset < bytes.length, 'fixture integer is complete');
      const byte = bytes[offset++];
      value += (byte & 127) * 2 ** shift;
      if (!(byte & 128)) return value;
    }
    throw new Error('Invalid fixture integer');
  }
  const result = [];
  while (offset < bytes.length) {
    const start = offset;
    const tag = integer();
    let value;
    if (tag % 8 === 0) value = integer();
    else {
      assert.equal(tag % 8, 2);
      const length = integer();
      assert.ok(length <= bytes.length - offset, 'fixture field is complete');
      value = bytes.subarray(offset, offset + length);
      offset += length;
    }
    result.push({number: Math.floor(tag / 8), value, raw: bytes.subarray(start, offset)});
  }
  return result;
}
function one(bytes, number) {
  const matches = fields(bytes).filter(item => item.number === number);
  assert.equal(matches.length, 1);
  return matches[0].value;
}
function message(id, body, type = 7) {
  return Buffer.concat([
    field(1, Buffer.concat([field(1, id), Buffer.from([16, type])])),
    field(2, body),
  ]);
}
function outputResult(command, output) {
  return Buffer.concat([field(1, command), field(3, field(1,
    Buffer.concat([field(1, 'Result'), field(2, JSON.stringify(output))])))]);
}
const receipt = {
  accepted: true,
  cancelled: false,
  requestId: fixture.args.RequestId,
  operationId: fixture.args.RequestId,
};
function reply(kind, id, command, faultCode = 7004) {
  if (kind === 'captured') {
    const original = Buffer.from(fixture.response, 'base64');
    return message(id, one(original, 2));
  }
  if (kind === 'protocol') {
    return message(id, field(3, Buffer.concat([
      fixed32(1, faultCode), field(2, 'Synthetic refusal'),
    ])), 0);
  }
  let operation = outputResult(command, receipt);
  if (kind === 'command') operation = Buffer.concat([
    field(1, command), field(4, Buffer.concat([
      fixed32(1, faultCode), field(2, 'Synthetic refusal'),
    ])),
  ]);
  if (kind === 'async') operation = Buffer.concat([
    field(1, command), field(2, 'Device.LocalAgent.Request.41.'),
  ]);
  if (kind === 'missing_outcome') operation = field(1, command);
  let operations = field(1, operation);
  if (kind === 'no_match') operations = Buffer.alloc(0);
  if (kind === 'multiple_results') operations = Buffer.concat([operations, operations]);
  const response = message(id, field(2, field(7, operations)));
  if (kind === 'truncated') return response.subarray(0, -1);
  if (kind === 'empty') return Buffer.alloc(0);
  return response;
}

async function operate(kind, {name = 'Apply', token = true, faultCode, status} = {}) {
  const command = `Device.X_LINKSYS_AutoIPoE.${name}()`;
  const args = {...fixture.args};
  if (name === 'Apply') args.Settings = JSON.stringify({password: secret});
  let calls = 0;
  let sentCommandKey;
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async request => {
    calls++;
    assert.ok(request instanceof Request);
    assert.equal(request.url, 'https://router.example/api/v1/usp');
    assert.equal(request.method, 'POST');
    assert.equal(request.headers.get('Authorization'), token ? 'Bearer synthetic-token' : null);
    const body = new Uint8Array(await request.arrayBuffer());
    const id = decoder.decode(one(one(body, 1), 1));
    const operation = one(one(one(body, 2), 1), 7);
    assert.equal(decoder.decode(one(operation, 1)), command);
    sentCommandKey = decoder.decode(one(operation, 2));
    const sentArgs = Object.fromEntries(fields(operation)
      .filter(item => item.number === 4)
      .map(({value}) => [decoder.decode(one(value, 1)), decoder.decode(one(value, 2))]));
    assert.deepEqual(sentArgs, args);
    if (kind === 'network') throw new TypeError('Failed to fetch');
    if (kind === 'timeout') throw new DOMException('Synthetic timeout', 'TimeoutError');
    const response = new Response(status ? null : reply(kind, id, command, faultCode),
      {status: status ?? 200, headers: {'content-type': 'application/octet-stream'}});
    Object.defineProperty(response, 'url', {value: request.url});
    if (kind === 'body') response.arrayBuffer = async () => {throw new TypeError('Body read interrupted');};
    return response;
  };
  let builder = new UspClientBuilder('https://router.example');
  if (token) builder = builder.authToken('synthetic-token');
  const client = builder.build();
  try {
    const response = await client.operate(command, args);
    assert.equal(calls, 1, 'a mutation is never dispatched twice');
    return {response, command, sentCommandKey};
  } finally {
    client.free();
    globalThis.fetch = originalFetch;
  }
}

for (const name of ['Apply', 'Reset', 'ResolvePending']) {
  test(`${name} retains synchronous output and request correlation`, async () => {
    const {response, sentCommandKey} = await operate(name === 'ResolvePending' ? 'captured' : 'success', {name});
    assert.equal(response.success, true);
    const data = response.result.data;
    assert.equal(data.commandKey, sentCommandKey);
    const output = JSON.parse(data.outputArgs.Result);
    assert.equal(output.requestId, fixture.args.RequestId);
    assert.equal(output.operationId, fixture.args.RequestId);
    assert.equal(output.cancelled, name === 'ResolvePending');
    assert.equal(output.accepted, name !== 'ResolvePending');
  });
}
for (const [kind, text] of [
  ['multiple_results', 'OperationResults'],
  ['missing_outcome', 'has no operation_resp'],
  ['truncated', 'decode'],
  ['empty', 'Empty response data'],
]) {
  test(`${kind} fails without accepting the receipt or replaying`, async () => {
    const {response, command} = await operate(kind);
    assert.equal(response.success, false);
    assert.equal(response.result.data?.outputArgs?.Result, undefined);
    assert.ok(response.result.error[command].errorMessage.includes(text));
  });
}
for (const kind of ['async', 'no_match']) {
  test(`${kind} does not produce a synchronous receipt`, async () => {
    const {response} = await operate(kind);
    assert.equal(response.success, true);
    assert.equal(response.result.data.outputArgs?.Result, undefined);
    assert.equal(kind === 'async' ? !!response.result.data.requestPath : response.result.data.noMatch, true);
  });
}
for (const faultCode of [7004, 7022, 4294967295]) {
  test(`command fault ${faultCode} preserves the unsigned fault code`, async () => {
    const {response, command} = await operate('command', {faultCode});
    assert.equal(response.success, false);
    assert.deepEqual(response.result.error[command], {
      errorCode: faultCode, errorMessage: 'Synthetic refusal',
    });
  });
}
for (const [kind, options, pattern] of [
  ['auth', {token: false, status: 401}, /HTTP 401/],
  ['http', {status: 401}, /HTTP 401/],
  ['http', {status: 503}, /HTTP 503/],
  ['network', {}, /Failed to fetch/],
  ['timeout', {}, /Synthetic timeout/],
  ['body', {}, /Body read interrupted/],
  ['protocol', {faultCode: 7004}, /Synthetic refusal.*7004/],
]) {
  test(`${kind} ${options.status ?? ''} preserves the shared failure response`, async () => {
    const {response, command} = await operate(kind, options);
    assert.equal(response.success, false);
    assert.match(response.result.error[command].errorMessage, pattern);
  });
}

const errorCases = JSON.parse(fs.readFileSync(new URL('./usp_operate_errors.json', import.meta.url)));
for (const fixture of errorCases) {
  test(`${fixture.name} matches the Dart error-mapping fixture`, async () => {
    const {response, command} = await operate(fixture.kind, {
      status: fixture.status, faultCode: fixture.faultCode,
    });
    assert.equal(response.success, false);
    const error = response.result.error[command];
    assert.equal(error.errorCode, fixture.errorCode);
    assert.ok(error.errorMessage.startsWith(fixture.errorMessage), fixture.name);
  });
}

test('shared client does not log operation arguments', async () => {
  const entries = [];
  const methods = ['log', 'info', 'warn', 'error', 'debug'];
  const originals = Object.fromEntries(methods.map(name => [name, console[name]]));
  for (const name of methods) console[name] = (...args) => entries.push(args.join(' '));
  try {
    await operate('success');
    await operate('command');
  } finally {
    for (const name of methods) console[name] = originals[name];
  }
  assert.ok(entries.every(entry => !entry.includes(secret)));
});
