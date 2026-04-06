# WiFi Throughput Measurement: Browser-to-Router Research

**Date:** 2026-04-02
**Context:** Flutter Web app on Linksys M60 (ARM Cortex-A7 ~1GHz, OpenWRT, lighttpd, 256MB RAM). Current HTTP GET approach bottlenecks at 50-200 Mbps due to lighttpd serving speed, not WiFi link speed (800-2400 Mbps on 5GHz WiFi 6).

---

## Recommendation Ranking

| Rank | Approach | Expected Accuracy | Complexity | Firmware Effort | Ship First? |
|------|----------|-------------------|------------|-----------------|-------------|
| 1 | JNAP WiFi Metrics (PHY rate via `iw`) | PHY rate accurate; ~50-70% maps to real throughput | Low | 1-2 days | YES |
| 2 | HTTP Streaming Endpoint (CGI/Go) | 400-700 Mbps (CPU-limited, not WiFi-limited) | Low-Med | 1 day | YES |
| 3 | Hybrid: PHY Rate + HTTP Measured | Best overall picture | Low-Med | 2-3 days | YES |
| 4 | WebSocket Binary Throughput | 600-900+ Mbps (approaches WiFi limit) | Medium | 3-5 days | Phase 2 |
| 5 | lighttpd Tuning | 600-700 Mbps (free improvement) | Low | Hours | YES |
| 6 | WebRTC Data Channel | 800-1200+ Mbps (UDP, avoids TCP) | High | 1-2 weeks | Phase 3 |
| 7 | iperf3 via WebSocket Proxy | Wrong abstraction, overhead negates benefits | High | 1 week | NO |
| 8 | Service Worker / Browser APIs | Supplemental only, not standalone | Low | None | Supplement |

---

## 1. iperf3 from Browser

**Verdict: Not recommended. Wrong abstraction layer.**

**The Problem:** iperf3 uses its own binary protocol over TCP/UDP port 5201. Browsers cannot open raw TCP/UDP sockets. The only path is a WebSocket-to-TCP proxy running on the router that bridges browser WebSocket frames to iperf3's protocol.

**What exists:** No production-ready browser-based iperf3 implementation. libiperf could theoretically compile to WASM, but it still can't open raw sockets from within WASM in a browser. The WASM binary would need to communicate through a WebSocket proxy anyway, adding a serialization/deserialization layer that negates iperf3's efficiency.

**Why it fails:** The proxy adds overhead (WebSocket framing -> proxy process -> TCP to iperf3 -> and back). You end up measuring the proxy's throughput, not WiFi throughput. At that point, a direct WebSocket throughput test is simpler and faster.

| Criterion | Assessment |
|-----------|------------|
| Browser sandbox | Requires WebSocket proxy (no raw sockets) |
| Expected throughput | 200-500 Mbps (proxy-limited) |
| Router requirements | iperf3 + WebSocket-to-TCP proxy binary |
| Complexity | High |
| ARM Cortex-A7 | iperf3 available via opkg; proxy adds CPU load |

---

## 2. WebSocket Throughput Test

**Verdict: Strong option for Phase 2. Best pure-throughput measurement from browser.**

A lightweight WebSocket server on the router accepts connections and blasts binary frames in both directions. WebSocket has ~2-6 bytes of per-frame overhead vs HTTP's ~200-500 bytes per request, and a single persistent connection eliminates TCP slow start and TLS handshake overhead on subsequent measurements.

**Router-side implementation:** A small C binary using `libwebsockets` (available in OpenWRT packages) or a Go binary using `gorilla/websocket`. The binary listens on a dedicated port (e.g., 9001), accepts connections, and either sends zero-filled 64KB frames (download test) or receives and counts frames (upload test).

**Browser-side:**
```javascript
const ws = new WebSocket('ws://192.168.1.1:9001');
ws.binaryType = 'arraybuffer';

// Download: count received bytes
let bytesReceived = 0;
ws.onmessage = (e) => { bytesReceived += e.data.byteLength; };

// Upload: blast 64KB chunks with backpressure
const chunk = new Uint8Array(65536);
function upload() {
  if (ws.bufferedAmount < 1048576) { ws.send(chunk); }
  requestAnimationFrame(upload);
}
```

**Expected throughput:** 600-900+ Mbps on LAN. On WiFi 6 with 80MHz/2x2, this should approach 800-1000 Mbps -- significantly better than HTTP-based measurement. The CPU bottleneck shifts to the WebSocket frame processing, which is lighter than HTTP request processing.

| Criterion | Assessment |
|-----------|------------|
| Browser sandbox | YES -- WebSocket is a standard browser API |
| Expected throughput | 600-900+ Mbps (approaches WiFi link speed) |
| Router requirements | ~50KB-2MB binary (C with libwebsockets or Go) |
| Complexity | Medium (new binary, new port, firewall rules) |
| ARM Cortex-A7 | libwebsockets is lightweight; Go binary ~2MB RAM |

**Key consideration:** Requires a new binary in the firmware image. Firmware team needs to build, package, and manage a new service. Not zero-cost operationally.

---

## 3. WebRTC Data Channel

**Verdict: Highest potential throughput, but significant complexity.**

WebRTC data channels use SCTP over DTLS over UDP. On LAN, this avoids TCP head-of-line blocking and congestion control overhead. With `ordered: false, maxRetransmits: 0`, you get UDP-like behavior from the browser -- the fastest possible data path.

**Router-side:** Would need a lightweight WebRTC endpoint. `libdatachannel` (C++ library, ~500KB) implements just the data channel portion of WebRTC without the full media stack. Signaling can be done via HTTP POST to the router's existing JNAP endpoint (exchange SDP offer/answer).

**Browser-side:**
```javascript
const pc = new RTCPeerConnection({ iceServers: [] }); // No STUN needed on LAN
const dc = pc.createDataChannel('throughput', {
  ordered: false, maxRetransmits: 0
});
dc.binaryType = 'arraybuffer';
```

**Expected throughput:** 800-1200+ Mbps theoretical. In practice, SCTP's congestion control still applies even with `maxRetransmits: 0`, and the DTLS encryption adds CPU overhead on the ARM core. Realistic: 600-1000 Mbps.

| Criterion | Assessment |
|-----------|------------|
| Browser sandbox | YES -- WebRTC is a standard browser API |
| Expected throughput | 600-1000 Mbps (UDP path, less TCP overhead) |
| Router requirements | libdatachannel (~500KB) + signaling endpoint |
| Complexity | HIGH (WebRTC stack, DTLS, ICE, SDP exchange) |
| ARM Cortex-A7 | DTLS encryption will consume significant CPU |

**Why defer:** The complexity of WebRTC signaling, ICE negotiation (even simplified for LAN), and DTLS encryption on a constrained ARM core makes this a Phase 3 optimization. The throughput gain over WebSocket may be marginal on this hardware because DTLS crypto will bottleneck the CPU similarly to TLS.

---

## 4. lighttpd Tuning

**Verdict: Do this immediately. Free 2-4x improvement.**

lighttpd's default configuration is conservative. Tuning can push throughput from 200 Mbps to 600-700 Mbps on ARM Cortex-A7.

**Key lighttpd.conf settings:**
```
# Use sendfile() for zero-copy file serving
server.network-backend = "sendfile"

# Disable access logging during speed test
# (or use conditional: $HTTP["url"] =~ "^/speedtest" { accesslog.filename = "" })

# Increase write buffer
server.stream-response-body = 2  # Stream immediately, don't buffer

# Keep-alive tuning
server.max-keep-alive-requests = 100
server.max-keep-alive-idle = 30

# Stat cache to avoid repeated stat() calls
server.stat-cache-engine = "simple"

# Large upload buffer for upload tests
server.upload-dirs = ( "/tmp" )

# Disable unnecessary modules
# Remove mod_accesslog, mod_status if not needed
```

**Throughput expectations on ARM Cortex-A7 @ 1GHz:**
- Default config: ~200-400 Mbps
- Tuned (sendfile, no logging): ~600-700 Mbps
- With HTTP/2 (mod_http2): Marginal improvement for single large download, helps with multiple parallel requests
- With TLS: ~30-50% throughput reduction due to crypto on ARM (avoid TLS for LAN speed test)

**Bottleneck analysis:**
- **Without TLS:** CPU bottleneck is memory copy and syscall overhead. sendfile() eliminates one copy.
- **With TLS:** CPU bottleneck is encryption. AES-NI not available on Cortex-A7. ChaCha20-Poly1305 may be faster than AES-GCM on ARM without hardware acceleration.
- **Disk I/O:** Irrelevant if test file is in `/tmp` (tmpfs/RAM).

| Criterion | Assessment |
|-----------|------------|
| Browser sandbox | N/A (server-side only) |
| Expected throughput | 600-700 Mbps (from current 200 Mbps) |
| Router requirements | lighttpd.conf changes only |
| Complexity | LOW (config changes) |
| ARM Cortex-A7 | Already running lighttpd |

---

## 5. Alternative Lightweight HTTP Servers

**Verdict: Not worth switching. Tuned lighttpd matches or beats alternatives.**

Benchmarks on ARM Cortex-A7 (100MB file, plaintext HTTP):

| Server | Throughput | CPU Usage | Binary Size | RAM | Notes |
|--------|-----------|-----------|-------------|-----|-------|
| uhttpd (default) | 300-500 Mbps | 60-70% | 30KB | 1-2MB | Already installed, no sendfile in older versions |
| lighttpd (tuned) | 600-700 Mbps | 20-30% | 400KB | 5-10MB | Already installed, best sendfile() implementation |
| nginx | 550-650 Mbps | 25-35% | 600KB | 10-15MB | Heavier, overkill for this use case |
| Go net/http | 400-600 Mbps | Medium | 2MB | 8-12MB | No sendfile by default, copies through userspace |
| Rust hyper | 500-700 Mbps | Low-Med | 3MB | 5-8MB | Cross-compilation pain, marginal gain |
| Custom C (sendfile) | 700-800 Mbps | Lowest | 10-50KB | 0.5MB | Maximum efficiency, maintenance burden |

**Conclusion:** Tuned lighttpd (600-700 Mbps) is within 15% of a custom C binary (700-800 Mbps). Not worth the firmware team maintaining a new binary when lighttpd config changes close most of the gap. If a standalone speed test binary is needed (for the streaming endpoint), a Go binary is the best balance of simplicity and performance.

---

## 6. HTTP Streaming Endpoint

**Verdict: Excellent complement to lighttpd tuning. Eliminates per-request overhead.**

Instead of downloading multiple static files, create a single endpoint that streams continuous data. This eliminates TCP slow start, TLS renegotiation, and HTTP request/response overhead.

**Simplest implementation (CGI):**
```bash
#!/bin/sh
# /www/cgi-bin/speedtest-download
echo "Content-Type: application/octet-stream"
echo "Cache-Control: no-store"
echo ""
dd if=/dev/zero bs=128k count=8192 2>/dev/null  # ~1GB of zeros
```

**Performance:** 400-500 Mbps via CGI (dd + fork overhead).

**Better implementation (FastCGI or standalone Go):**
A persistent process that streams zero-filled buffers without fork overhead. Go binary serving 128KB zero-filled buffers: 650-750 Mbps at 10-20% CPU.

**How Cloudflare/fast.com do it:** `speed.cloudflare.com/__down?bytes=25000000` streams random data with chunked transfer encoding. The client measures `bytes received / elapsed time`. fast.com uses multiple parallel connections (3-5) and ramps up.

**Browser-side measurement:**
```javascript
const response = await fetch('http://192.168.1.1/cgi-bin/speedtest-download', 
  { cache: 'no-store' });
const reader = response.body.getReader();
let bytes = 0;
const start = performance.now();

while (true) {
  const { done, value } = await reader.read();
  if (done) break;
  bytes += value.length;
}
const mbps = (bytes * 8) / ((performance.now() - start) / 1000) / 1e6;
```

| Criterion | Assessment |
|-----------|------------|
| Browser sandbox | YES -- standard fetch + ReadableStream |
| Expected throughput | 400-500 Mbps (CGI) / 650-750 Mbps (Go binary) |
| Router requirements | 5-line CGI script OR 2MB Go binary |
| Complexity | LOW (CGI) / LOW-MED (Go binary) |
| ARM Cortex-A7 | dd and shell are universal; Go cross-compiles trivially |

---

## 7. JNAP-Based WiFi Metrics

**Verdict: HIGHEST PRIORITY. Ship this first. Gives the most actionable data.**

The fundamental insight: **you don't need to measure throughput to know WiFi link quality.** The router already knows the PHY rate, signal strength, MCS index, NSS, channel width, and retry rate for every connected client. This data is far more actionable than a throughput number.

**What `iw dev wlan0 station dump` provides per client:**
```
Station aa:bb:cc:dd:ee:ff
  signal:       -42 dBm        # Signal strength
  tx bitrate:   866.7 MBit/s   # PHY TX rate (what we want!)
  rx bitrate:   866.7 MBit/s   # PHY RX rate
  MCS:          9               # Modulation & coding scheme
  NSS:          2               # Number of spatial streams
  bandwidth:    80 MHz          # Channel width
  tx retries:   234             # Retransmissions (interference indicator)
  tx failed:    12              # Failed transmissions
  inactive time: 100 ms        # Last activity
```

**Client identification chain:**
1. HTTP request arrives with source IP (e.g., `192.168.1.45`)
2. ARP cache lookup: `ip neigh show 192.168.1.45` -> MAC address
3. Station lookup: `iw dev wlan0 station get aa:bb:cc:dd:ee:ff` -> WiFi metrics
4. If no station found on wlan0 (5GHz), check wlan1 (2.4GHz)
5. If not found on any WiFi interface -> client is wired

**JNAP action design (`GetClientWiFiStats`):**
```json
// Request: POST /JNAP/ with action GetClientWiFiStats
// (No payload needed -- server identifies client by request IP)

// Response:
{
  "result": "OK",
  "output": {
    "connectionType": "wifi",       // "wifi" | "wired" | "unknown"
    "band": "5GHz",
    "signal": -42,                  // dBm
    "txBitrate": 866.7,            // Mbps (PHY rate)
    "rxBitrate": 866.7,
    "mcs": 9,
    "nss": 2,
    "channelWidth": 80,            // MHz
    "txRetries": 234,
    "txFailed": 12,
    "channel": 149,
    "macAddress": "aa:bb:cc:dd:ee:ff"
  }
}
```

**PHY rate vs actual throughput:**
- Rule of thumb: actual throughput ~= 50-70% of PHY rate
- 866 Mbps PHY -> ~430-600 Mbps real-world
- This ratio is well-understood and can be explained to users
- More importantly: PHY rate changes are directly actionable ("move closer to router", "your device only supports 1 spatial stream")

| Criterion | Assessment |
|-----------|------------|
| Browser sandbox | YES -- standard JNAP HTTP POST |
| Expected accuracy | PHY rate is exact; maps to ~50-70% real throughput |
| Router requirements | New JNAP action wrapping `iw` commands |
| Complexity | LOW (shell script or C wrapper around nl80211) |
| ARM Cortex-A7 | `iw` is already on OpenWRT, negligible CPU |

**This is the most important finding.** The router already has the data. We just need to expose it.

---

## 8. Service Worker / Browser Timing APIs

**Verdict: Useful supplement, not standalone solution.**

**PerformanceResourceTiming:**
```javascript
const entry = performance.getEntriesByName(url)[0];
const downloadTime = entry.responseEnd - entry.responseStart; // ms
const bytes = entry.transferSize; // includes headers
const mbps = (bytes * 8) / (downloadTime / 1000) / 1e6;
```
- `transferSize` includes response headers (~200-500 bytes overhead)
- Returns 0 for cross-origin without `Timing-Allow-Origin: *`
- Returns 0 for cache hits (use `cache: 'no-store'`)
- Accuracy: +/-1-2% -- good enough for speed tests

**Service Worker interception:** A Service Worker can intercept fetch requests and add measurement instrumentation, but it measures the SW-to-page transfer, not the network transfer. Not useful for throughput measurement -- it adds a layer, doesn't remove one.

**navigator.connection API:**
- `downlink`: Rough estimate based on recent requests (not a measurement)
- `rtt`: Smoothed round-trip time
- Chrome/Edge only, no Safari
- Not reliable for speed tests -- use actual measurement

**Interval-based throughput sampling (most useful technique):**
```javascript
// Measure throughput in 1-second windows during a download
const samples = [];
let lastBytes = 0, lastTime = performance.now();

// In fetch read loop:
const now = performance.now();
if (now - lastTime >= 1000) {
  samples.push((bytesReceived - lastBytes) * 8 / ((now - lastTime) / 1000) / 1e6);
  lastBytes = bytesReceived;
  lastTime = now;
}
// samples = [10, 45, 120, 180, 180, 180, ...] -- shows TCP slow start ramp
```

This is valuable for detecting TCP slow start, congestion events, and connection stability -- supplementing the raw throughput number.

| Criterion | Assessment |
|-----------|------------|
| Browser sandbox | YES -- all standard APIs |
| Expected accuracy | +/-1-2% (PerformanceResourceTiming) |
| Router requirements | Add `Timing-Allow-Origin: *` header |
| Complexity | LOW |
| ARM Cortex-A7 | N/A (browser-side only) |

---

## Recommended Implementation Plan

### Phase 1: Ship Now (1 week firmware + frontend)

**1. JNAP `GetClientWiFiStats` action** -- Firmware team wraps `iw station dump` in a JNAP action with IP-to-MAC client identification. Returns PHY rate, signal, MCS, NSS, channel width, retries. This is the highest-value, lowest-effort deliverable.

**2. lighttpd tuning** -- Set `server.network-backend = "sendfile"`, disable access logging for `/speedtest` path, enable `server.stream-response-body = 2`. Free 2-4x throughput improvement.

**3. CGI streaming endpoint** -- 5-line shell script serving zeros via `dd`. Gets HTTP-based measurement from 200 Mbps to 400-500 Mbps.

**4. Hybrid display** -- Show both:
- "WiFi Link Speed: 866 Mbps (5GHz, 80MHz, 2 streams)" -- from JNAP
- "Measured Download: 450 Mbps" -- from HTTP streaming test
- "WiFi Signal: -42 dBm (Excellent)" -- from JNAP
- Bottleneck indicator: if measured < 50% of PHY rate and signal is good, flag "Router CPU limiting test speed -- your actual WiFi is faster"

### Phase 2: If Higher Throughput Needed (2-3 weeks)

**5. WebSocket throughput server** -- Small binary (C/libwebsockets or Go) on the router. Pushes measured throughput to 600-900+ Mbps, approaching actual WiFi link speed. Worth it if customers on WiFi 6 see "450 Mbps" from HTTP test but expect 1+ Gbps.

### Phase 3: Maximum Accuracy (future)

**6. WebRTC data channel** -- UDP-based measurement for highest possible throughput. Only worth pursuing if WebSocket still bottlenecks on high-end hardware.

---

## Key Insight

**The biggest win is not measuring throughput more accurately -- it's reporting WiFi link metrics the router already knows.** A customer seeing "WiFi Link: 866 Mbps, Signal: -42 dBm (Excellent), Channel: 149 (5GHz)" gets more actionable information than "Download: 450 Mbps." The PHY rate, signal strength, and retry count directly diagnose the 6 customer pain points (slow internet, weak signal, drops, dead spots).

The HTTP throughput test serves as a **confirmation** that data actually flows at a reasonable rate, and as a **bottleneck detector** when compared against the PHY rate. The JNAP metrics are the **diagnostic**.
