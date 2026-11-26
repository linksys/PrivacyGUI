// How the vendored usp-client reports a failed WRITE (#1666).
//
// Set, setOrdered, Add and Delete through web/usp_client.js + usp_client_bg.wasm,
// with `fetch` replaced and the USP replies built by hand, as
// usp_operate_test.mjs does for Operate. What `UspClient.throwIfUnanswered`
// decides by, pinned at the source:
// - the router never answering (401, 5xx, a lost connection, a timeout, an
//   unreadable body) RESOLVES, as `kind: request` with the client's 9999;
// - the router refusing the whole request is `kind: request` too, with the
//   router's own code and text — only the code tells the two apart;
// - each is one request: the client never sends a write twice.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {webcrypto} from 'node:crypto';
import {test} from 'node:test';

globalThis.crypto ??= webcrypto;
const source = fs.readFileSync(new URL('../../web/usp_client.js', import.meta.url), 'utf8');
const {default: init, UspClientBuilder} = await import(
  `data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
await init({module_or_path: fs.readFileSync(new URL('../../web/usp_client_bg.wasm', import.meta.url))});
const encoder = new TextEncoder();
const decoder = new TextDecoder();

// Protocol helpers, the same encoding usp_operate_test.mjs builds by hand.
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
function lengthDelimited(bytes, number) {
  let offset = 0;
  const integer = () => {
    let value = 0;
    for (let shift = 0; shift < 49; shift += 7) {
      assert.ok(offset < bytes.length, 'request integer is complete');
      const byte = bytes[offset++];
      value += (byte & 127) * 2 ** shift;
      if (!(byte & 128)) return value;
    }
    throw new Error('Invalid request integer');
  };
  while (offset < bytes.length) {
    const tag = integer();
    if (tag % 8 === 0) { integer(); continue; }
    if (tag % 8 === 5) { offset += 4; continue; }
    const length = integer();
    const value = bytes.subarray(offset, offset + length);
    offset += length;
    if (Math.floor(tag / 8) === number) return value;
  }
  throw new Error(`field ${number} not found`);
}
// USP Header.MsgType: ERROR 0, SET_RESP 5.
function message(id, body, type) {
  return Buffer.concat([
    field(1, Buffer.concat([field(1, id), Buffer.from([16, type])])),
    field(2, body),
  ]);
}
const refusal = (id, code) =>
  message(id, field(3, Buffer.concat([fixed32(1, code), field(2, 'Synthetic refusal')])), 0);
// SetResp > UpdatedObjectResult > OperationStatus.oper_success > UpdatedInstanceResult.
const setAccepted = id => message(id, field(2, field(4, field(1, Buffer.concat([
  field(1, 'Device.WiFi.SSID.1.'),
  field(2, field(2, field(1, Buffer.concat([
    field(1, 'Device.WiFi.SSID.1.'),
    field(3, Buffer.concat([field(1, 'SSID'), field(2, 'NewHome')])),
  ])))),
])))), 5);

const writes = {
  set: client => client.set({'Device.WiFi.SSID.1.SSID': 'NewHome'}, {allowPartial: false}),
  setOrdered: client => client.setOrdered([{'Device.WiFi.SSID.1.SSID': 'NewHome'}], false),
  add: client => client.add({path: 'Device.NAT.PortMapping.', params: {ExternalPort: '8080'}}),
  delete: client => client.delete('Device.NAT.PortMapping.3.'),
};

async function write(verb, reply) {
  let calls = 0;
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async request => {
    calls++;
    assert.equal(request.url, 'https://router.example/api/v1/usp');
    const body = new Uint8Array(await request.arrayBuffer());
    const id = decoder.decode(lengthDelimited(lengthDelimited(body, 1), 1));
    return reply(id, request);
  };
  const client = new UspClientBuilder('https://router.example').authToken('synthetic-token').build();
  try {
    const response = await writes[verb](client);
    assert.equal(calls, 1, 'a write is never dispatched twice');
    return response;
  } finally {
    client.free();
    globalThis.fetch = originalFetch;
  }
}

function respond(payload, request, status = 200) {
  const response = new Response(payload, {status, headers: {'content-type': 'application/octet-stream'}});
  Object.defineProperty(response, 'url', {value: request.url});
  return response;
}

const unanswered = [
  ['401', (_, r) => respond(null, r, 401), /^Transport error: HTTP error: HTTP 401$/],
  ['503', (_, r) => respond(null, r, 503), /^Transport error: HTTP error: HTTP 503$/],
  ['lost connection', () => { throw new TypeError('Failed to fetch'); }, /^Transport error: .*Failed to fetch/],
  ['timeout', () => { throw new DOMException('Synthetic timeout', 'TimeoutError'); }, /^Transport error: .*Synthetic timeout/],
  ['unreadable body', (_, r) => {
    const response = respond(Buffer.alloc(0), r);
    response.arrayBuffer = async () => { throw new TypeError('Body read interrupted'); };
    return response;
  }, /^Transport error: .*Body read interrupted/],
];

for (const verb of Object.keys(writes)) {
  for (const [name, reply, text] of unanswered) {
    test(`${verb}: ${name} resolves as kind request, 9999`, async () => {
      const response = await write(verb, reply);
      assert.equal(response.success, false);
      assert.equal(response.result.errors.length, 1);
      const [entry] = response.result.errors;
      assert.equal(entry.kind, 'request');
      assert.equal(entry.errorCode, 9999);
      assert.match(entry.errorMessage, text);
    });
  }

  test(`${verb}: a refusal of the whole request is kind request with the router's code`, async () => {
    const response = await write(verb, (id, r) => respond(refusal(id, 7005), r));
    assert.equal(response.success, false);
    const [entry] = response.result.errors;
    assert.equal(entry.kind, 'request');
    assert.equal(entry.errorCode, 7005);
    assert.equal(entry.errorMessage, 'Synthetic refusal');
  });
}

test('set: an accepted write has no errors', async () => {
  const response = await write('set', (id, r) => respond(setAccepted(id), r));
  assert.equal(response.success, true);
  assert.deepEqual(response.result.errors ?? [], []);
});
