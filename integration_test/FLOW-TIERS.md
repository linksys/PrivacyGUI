# Integration Flow Tiers: Mockable vs Device-Bound

> Proposal from QA (Deven). Splits the 21 integration flows into a per-PR mock tier
> and a nightly device tier so the suite runs automatically instead of manually.
> Companion workflows: `.github/workflows/ci-integration-mock.yml` and
> `ci-integration-device.yml`.

## Classification principle

Every flow can technically run with mocked JNAP. The split is about where the
regression value lives:

- **MOCKABLE**: the flow asserts UI behavior and the UI-to-JNAP contract (forms,
  validation, CRUD echo, navigation). A mocked JNAP layer preserves nearly all of its
  regression value. Run per-PR, headless, no router.
- **DEVICE-BOUND**: the flow's value depends on real device behavior (radio apply,
  WAN state machines, device-mode transitions, real measurements). Run nightly on the
  lab router via `integration_web.sh`.

**Mock-tier caveat (review W-6):** the mock workflow calls `flutter drive` directly,
so the `setUp`/`tearDown` hooks declared in `test_meta/*.json` do NOT run in the mock
tier. Mock-tier flows must therefore be self-contained against the mocked JNAP state.
Whether all 13 actually are is a first-run validation item.

**Tag caveat (review W-7):** `test_meta` tags cross tiers (e.g. `menu` is on the
mockable `menu_test` AND device-bound wifi/speed flows). Do not use bare tags to
select a tier with `integration_web.sh -t`; the `tier` field (open item 3) is the
real fix.

## The split (13 mockable / 8 device-bound)

### Mockable, per-PR tier

| Flow | Why mockable |
|---|---|
| `administration_test` | Toggle persistence is a JNAP Set/Get echo, no HW behavior asserted |
| `advanced_routing_test` | Route CRUD plus validation error rendering |
| `apps_and_gaming_test` | DDNS / port-forwarding / triggering form CRUD |
| `dashboard_home_test` | Outer-layer cards and navigation. OPEN (review W-8): test_meta says the flow includes Speed Test interaction; whether that triggers a real measurement (which a mock run cannot answer) or only renders the card needs confirming before this row is trusted |
| `dhcp_reservations_test` | Add/edit reservation UI plus Get-back verification |
| `dmz_test` | Enable switch plus IP/MAC form management |
| `firewall_test` | Switch states plus IPv6 port-service CRUD |
| `instant_admin_test` | Password/timezone forms; manual-FW-update entry stubbed |
| `instant_privacy_test` | UI contract is mockable. Live runs also risk kicking the test client off WiFi (MAC filter), an extra reason to keep it in the mock tier |
| `instant_safety_test` | Enable flow, JNAP contract only |
| `local_network_settings_test` | Hostname/LAN IP/DHCP-pool forms; mock avoids the real re-IP dance. Open: confirm the test does not assert post-re-IP reachability (mock cannot answer that) |
| `menu_test` | Pure navigation, every card and button on the dashboard menu |
| `recovery_and_login_test` | Login and forgot-password flow against mocked auth responses |

### Device-bound, nightly tier

| Flow | Why device-bound |
|---|---|
| `factory_reset_setup_test` | Full PnP on a genuinely reset device; device-mode state machine |
| `prepaired_reset_setup_test` | Pre-paired PnP path; mesh pairing state is real-device-only |
| `incredible_wifi_test` | Band settings must apply to real radios |
| `incredible_wifi_advanced_and_mac_filtering_test` | Advanced radio switches, MLO alert, MAC filtering against real clients |
| `internet_settings_set_1_test` | IPv4 DHCP/Static/PPPoE, real WAN state transitions |
| `internet_settings_set_2_test` | PPTP/L2TP/Bridge mode, WAN mode switching |
| `internet_settings_set_3_test` | IPv6 DHCP/Static/PPPoE, dual-stack behavior |
| `speed_test_test` | Real measurement; meta itself says only run on devices supporting speed test |

## Open items for review

1. ~~Mock flag~~ **RESOLVED (review round 1, C-1):** the app reads the `force`
   dart-define (`lib/constants/build_config.dart`); the workflow now passes
   `--dart-define=force=local`, matching `integration_web.sh:219`.
2. **Two rows worth a second opinion**: `dashboard_home_test` (Speed Test interaction
   depth, see W-8 note in its row) and `local_network_settings_test` (post-re-IP
   reachability assertion).
3. **`tier` field proposal**: add `"tier": "mock" | "device"` to `test_meta/*.json` so
   selection is data-driven instead of hardcoded lists, and cross-tier tags (W-7) stop
   being a foot-gun. Happy to do this as a follow-up once the classification is agreed.
4. **Model genericity**: flows must stay model-generic across M60/M61/M62. Known model
   difference: band count (6 GHz coverage in `incredible_wifi_test` is conditional on
   tri-band hardware). Proposal is to data-drive model differences, never branch test
   logic on model.
5. **2.x line**: `integration_test/` exists on `main` and the 1.x line only. Should the
   suite (or the mock tier at least) be ported to the `usp`/2.x line?
6. **Admin password threading (review W-5)**: the device workflow exports
   `ROUTER_ADMIN_PASSWORD`, but `integration_web.sh` never reads it; the harness gets
   the password from `is_default_admin_password_or_get_password()` (default or config
   JSON). Before the first live nightly run, thread the secret into the harness config
   (or agree the lab device stays on the label-default password, which factory resets
   restore anyway).
