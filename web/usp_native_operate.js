// Native TR-369 Operate for the synchronous Auto-IPoE adapter only.
// Decode structured operation results and preserve the existing behavior
// of every command outside the Auto-IPoE service.
const commands = new Set(['Apply', 'Reset', 'ResolvePending'].map(
  name => `Device.X_LINKSYS_AutoIPoE.${name}()`));
const utf8 = new TextEncoder();
const text = new TextDecoder('utf-8', {fatal: true});
const join = (...arrays) => Uint8Array.from(arrays.flatMap(a => Array.from(a)));
function varint(n) {
  const bytes = [];
  do { bytes.push((n & 127) | (n > 127 ? 128 : 0)); n = Math.floor(n / 128); } while (n);
  return Uint8Array.from(bytes);
}
function field(number, value) {
  const bytes = typeof value === 'string' ? utf8.encode(value) : value;
  return join(varint(number * 8 + 2), varint(bytes.length), bytes);
}
function fields(bytes) {
  if (!(bytes instanceof Uint8Array) || bytes.length > 262144) throw new Error('Invalid USP message size');
  let offset = 0;
  function integer() {
    let value = 0;
    for (let i = 0; i < 8; i++) {
      if (offset >= bytes.length) throw new Error('Truncated USP integer');
      const b = bytes[offset++]; value += (b & 127) * 2 ** (7 * i);
      if (!Number.isSafeInteger(value)) throw new Error('Invalid USP integer');
      if (!(b & 128)) return value;
    }
    throw new Error('Invalid USP integer');
  }
  const result = new Map();
  while (offset < bytes.length) {
    const tag = integer(), number = Math.floor(tag / 8), wire = tag % 8;
    if (!number) throw new Error('Invalid USP field');
    let value;
    if (wire === 0) value = integer();
    else if ([1, 2, 5].includes(wire)) {
      const length = wire === 2 ? integer() : wire === 1 ? 8 : 4;
      if (length > bytes.length - offset) throw new Error('Truncated USP field');
      value = bytes.slice(offset, offset + length); offset += length;
    } else throw new Error('Unsupported USP wire type');
    const values = result.get(number) || []; values.push(value); result.set(number, values);
  }
  return result;
}
function one(map, key) {
  const values = map.get(key);
  if (!values || values.length !== 1) throw new Error('Missing or duplicate USP field');
  return values[0];
}
export function encodeOperate(command, args, messageId, commandKey) {
  if (!commands.has(command)) throw new Error('Unsupported native command');
  const inputs = Object.entries(args).map(([key, value]) => {
    if (typeof value !== 'string') throw new Error('Invalid USP argument');
    return field(4, join(field(1, key), field(2, value)));
  });
  const operation = join(field(1, command), field(2, commandKey), new Uint8Array([24, 1]), ...inputs);
  const message = join(field(1, join(field(1, messageId), new Uint8Array([16, 6]))),
    field(2, field(1, field(7, operation))));
  if (message.length > 32768) throw new Error('USP request too large');
  return message;
}
export function decodeOperate(bytes, command, messageId, commandKey) {
  const message = fields(bytes), header = fields(one(message, 1));
  if (text.decode(one(header, 1)) !== messageId) throw new Error('USP message ID mismatch');
  const body = fields(one(message, 2));
  if (body.has(3)) {
    const error = fields(one(body, 3));
    throw new Error(`USP error ${one(error, 1)}: ${text.decode(one(error, 2))}`);
  }
  if (one(header, 2) !== 7) throw new Error('Unexpected USP response type');
  const response = fields(one(body, 2));
  const operation = fields(one(fields(one(response, 7)), 1));
  if (text.decode(one(operation, 1)) !== command) throw new Error('USP command mismatch');
  if ([2, 3, 4].filter(k => operation.has(k)).length !== 1) throw new Error('Invalid USP operation result');
  if (operation.has(4)) {
    const error = fields(one(operation, 4));
    throw new Error(`USP command error ${one(error, 1)}: ${text.decode(one(error, 2))}`);
  }
  // Auto-IPoE acknowledges synchronously; an async result is not acceptance.
  const outputArgs = Object.create(null);
  const output = fields(one(operation, 3));
  for (const bytes of output.get(1) || []) {
    const pair = fields(bytes), key = text.decode(one(pair, 1));
    if (Object.hasOwn(outputArgs, key)) throw new Error('Duplicate USP output argument');
    outputArgs[key] = text.decode(one(pair, 2));
  }
  return {commandKey, outputArgs};
}
export async function nativeOperate(client, command, args, fetcher = fetch) {
  const messageId = crypto.randomUUID(), commandKey = crypto.randomUUID();
  const payload = encodeOperate(command, args, messageId, commandKey);
  const token = client.getToken();
  if (!token) throw new Error('Authentication required');
  // Exactly one dispatch. Timeout/reply loss is reconciled by RequestId, never retried.
  const response = await fetcher(new URL('/api/v1/usp', client.baseUrl()), {
    method: 'POST', credentials: 'include',
    headers: {'Content-Type': 'application/octet-stream', 'Authorization': `Bearer ${token}`},
    body: payload, signal: AbortSignal.timeout(120000),
  });
  if (!response.ok) throw new Error(`USP HTTP ${response.status}`);
  return decodeOperate(new Uint8Array(await response.arrayBuffer()), command, messageId, commandKey);
}
export function installNativeOperate(UspClient) {
  const original = UspClient.prototype.operate;
  UspClient.prototype.operate = function(command, args) {
    return commands.has(command) ? nativeOperate(this, command, args) : original.call(this, command, args);
  };
}
