# UspService → UspClient 重新命名執行計劃

## 概述

為避免 `UspService` 與業務服務層（如 `SystemInfoService`）的命名混淆，將核心 USP 協議客戶端重新命名為 `UspClient`，確保職責邊界清晰。

## 重新命名範圍

**總計影響檔案數量**: 約 200+ 檔案
- 核心檔案: 2 個
- Codegen 生成檔案: 27 個
- Provider 匯入: 53 個
- 類別參考: 107 個
- 文件檔案: 25+ 個
- Demo 資料: 3 個

## 詳細檔案清單

### 1. 核心檔案重新命名（主要變更）
```bash
# 主服務檔案
lib/core/usp/services/usp_service.dart → lib/core/usp/services/usp_client.dart

# Provider 檔案  
lib/core/usp/providers/usp_service_provider.dart → lib/core/usp/providers/usp_client_provider.dart
```

### 2. Codegen 相依性（關鍵更新）
```bash
# Memory 檔案中的 CLI 參數
/Users/austin.chang/.claude/projects/-Users-austin-chang-flutter-workspaces-privacyGUI-PrivacyGUI/memory/MEMORY.md
# 更新行:
# 從: --client-import 'package:privacy_gui/usp/services/usp_service.dart'
# 到: --client-import 'package:privacy_gui/usp/services/usp_client.dart'

# Codegen 範例腳本
doc/usp/codegen_example/run_examples.sh
# 更新 get_client_class() 函式返回值: "UspService" → "UspClient"

# Codegen stub 檔案重新命名
doc/usp/codegen_example/stubs/dart/usp_service.dart → usp_client.dart
```

### 3. 自動生成程式碼（27個檔案）
將透過重新執行 codegen 自動更新：
```bash
lib/generated/admin_users.g.dart
lib/generated/connected_devices.g.dart
lib/generated/dhcp_clients.g.dart
lib/generated/dhcp_reservations.g.dart
lib/generated/dmz.g.dart
lib/generated/ethernet_interfaces.g.dart
lib/generated/firewall_chain_rules.g.dart
lib/generated/firmware_images.g.dart
lib/generated/ipv6settings.g.dart
lib/generated/ipv6port_service.g.dart
lib/generated/lan_network_info.g.dart
lib/generated/multi_interface_traffic_stats.g.dart
lib/generated/network_diagnostics.g.dart
lib/generated/port_forwarding.g.dart
lib/generated/port_triggering.g.dart
lib/generated/static_routing.g.dart
lib/generated/system_info.g.dart
lib/generated/time_settings.g.dart
lib/generated/vendor_log_files.g.dart
lib/generated/wan_operations.g.dart
lib/generated/wan_settings.g.dart
lib/generated/wan_status.g.dart
lib/generated/wan_traffic_stats.g.dart
lib/generated/wi_fi_access_points.g.dart
lib/generated/wi_fi_radios.g.dart
lib/generated/wi_fi_ssids.g.dart
lib/generated/wifi_clients.g.dart
```

### 4. Provider 匯入更新（53個檔案）
所有包含 `uspServiceProvider` 參考的檔案：
```bash
lib/core/session/services/session_service.dart
lib/core/usp/providers/sse_providers.dart
lib/core/usp/providers/usp_auth_coordinator.dart
lib/demo/providers/demo_overrides.dart
lib/page/admin/providers/system_info_data_provider.dart
lib/page/admin/providers/time_data_provider.dart
lib/page/admin/providers/usp_admin_notifier.dart
lib/page/admin/services/usp_admin_service.dart
lib/page/apps/views/usp_apps_view.dart
lib/page/dashboard/orchestrator/dashboard_orchestrator.dart
lib/page/dashboard/widgets/package_widget_renderer.dart
lib/page/devices/providers/devices_data_provider.dart
lib/page/dhcp/services/usp_dhcp_service.dart
lib/page/dmz/services/usp_dmz_service.dart
lib/page/firewall/providers/firewall_data_provider.dart
lib/page/firewall/services/usp_firewall_service.dart
lib/page/instant_privacy/services/instant_privacy_service.dart
lib/page/instant_safety/services/instant_safety_service.dart
lib/page/internet_settings/providers/usp_internet_settings_notifier.dart
lib/page/internet_settings/providers/wan_data_provider.dart
lib/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart
lib/page/local_network/providers/dhcp_data_provider.dart
lib/page/local_network/providers/ethernet_data_provider.dart
lib/page/local_network/providers/lan_data_provider.dart
lib/page/local_network/services/usp_local_network_service.dart
lib/page/port_forwarding/providers/port_forwarding_data_provider.dart
lib/page/port_forwarding/providers/port_triggering_data_provider.dart
lib/page/port_forwarding/services/usp_port_forwarding_service.dart
lib/page/_shared/providers/usp_system_monitor_notifier.dart
lib/page/_shared/providers/usp_traffic_analysis_notifier.dart
lib/page/static_routing/services/usp_static_routing_service.dart
lib/page/system_log/services/usp_system_log_service.dart
lib/page/test_console/views/usp_test_console_view.dart
lib/page/wifi_settings/providers/usp_wifi_settings_provider.dart
lib/page/wifi_settings/providers/wifi_data_provider.dart
lib/page/wifi_settings/services/usp_wifi_advanced_service.dart
lib/page/wifi_settings/services/usp_wifi_settings_service.dart

# 相關測試檔案
test/core/usp/providers/sse_providers_test.dart
test/page/admin/providers/system_info_data_provider_test.dart
test/page/admin/providers/time_data_provider_test.dart
test/page/admin/providers/usp_admin_notifier_test.dart
test/page/dashboard/widgets/package_widget_renderer_test.dart
test/page/devices/providers/devices_data_provider_test.dart
test/page/internet_settings/providers/usp_internet_settings_notifier_test.dart
test/page/internet_settings/providers/wan_data_provider_test.dart
test/page/local_network/providers/dhcp_data_provider_test.dart
test/page/local_network/providers/ethernet_data_provider_test.dart
test/page/local_network/providers/lan_data_provider_test.dart
test/page/_shared/providers/usp_system_monitor_notifier_test.dart
test/page/_shared/providers/usp_traffic_analysis_notifier_test.dart
test/page/wifi_settings/providers/usp_wifi_settings_notifier_test.dart
```

### 5. 類別參考更新（其餘檔案）
包含 `UspService` 類別參考但不在上述清單的檔案：
```bash
lib/core/usp/services/sse_manager.dart
lib/core/usp/services/sse_operation_awaiter.dart
lib/core/usp/services/usp_bridge_client_base.dart
lib/core/usp/services/usp_bridge_client_web.dart
lib/core/usp/web/usp_client_wasm.dart
lib/core/usp/web/usp_wasm_init_web.dart
lib/core/utils/logger.dart
lib/demo/usp/demo_usp_service.dart
lib/di.dart
lib/page/_shared/providers/mesh_node_enricher.dart
lib/page/_shared/providers/wifi_client_enricher.dart
lib/page/_shared/services/usp_pdf_service.dart

# 所有相關測試檔案
test/core/usp/integration/codegen_verification_test.dart
test/core/usp/mocks.dart
test/core/usp/services/sse_manager_test.dart
test/core/usp/services/sse_operation_awaiter_test.dart
test/page/admin/services/usp_admin_service_test.dart
test/page/dhcp/services/usp_dhcp_service_test.dart
test/page/dmz/services/usp_dmz_service_test.dart
test/page/firewall/services/usp_firewall_service_test.dart
test/page/instant_privacy/services/usp_instant_privacy_service_test.dart
test/page/instant_safety/services/usp_instant_safety_service_test.dart
test/page/internet_settings/services/usp_internet_settings_service_test.dart
test/page/ipv6_port_service/services/usp_ipv6_port_service_service_test.dart
test/page/local_network/services/usp_local_network_service_test.dart
test/page/port_forwarding/services/usp_port_forwarding_service_test.dart
test/page/static_routing/services/usp_static_routing_service_test.dart
test/page/system_log/services/usp_system_log_service_test.dart
test/page/wifi_settings/services/usp_wifi_advanced_service_test.dart
test/page/wifi_settings/services/usp_wifi_settings_service_test.dart
```

### 6. 文件檔案（25+個檔案）
```bash
CHANGELOG.md
constitution.md
doc/_archived/usp_pages_architecture_v2.1.0.md
doc/architecture/USP_ARCHITECTURE.md
doc/architecture/usp-naming-refactor.md
doc/architecture/usp-structured-response-integration.md
doc/modular_apps/IMPLEMENTATION.md
doc/refactoring/domain-split-playbook.md
doc/USP_MILESTONE_1_SPECIFICATION.md
doc/usp/integration/feature_roadmap.md
doc/usp/integration/pnp-usp-migration.md
doc/usp/integration/sse_implementation.md
doc/usp/integration/USP_DATA_MODEL_MAPPING.md
doc/usp/issues/internet-settings-fix-design.md
doc/usp/issues/subscription-notify-blocked.md
doc/usp/router/router_usp_guide.md
doc/usp/unit-test-coverage-plan.md
doc/usp/USP_CLIENT_INTERFACE_SPECIFICATION.md
doc/usp/USP_CLIENT_ROOT_CAUSE_FIX_IMPLEMENTATION_PLAN.md
doc/usp/USP_FEATURES_MATRIX.md
doc/usp/USP_V011_DART_IMPLEMENTATION_PLAN.md
doc/usp/yaml-spec.md
doc/usp_pages_architecture_review_2026-03-18.md
```

### 7. Demo 資料檔案
```bash
assets/resources/demo_usp_data.json
build/flutter_assets/assets/resources/demo_usp_data.json
build/unit_test_assets/assets/resources/demo_usp_data.json
```

## 執行順序（關鍵）

### 階段 1：Codegen 設定更新
1. ✅ **更新 Memory 檔案**
   - 修改 CLI 參數中的匯入路徑

2. ✅ **更新 codegen 範例腳本**
   - 修改 `get_client_class()` 函式返回值

3. ✅ **重新命名 stub 檔案**
   - `usp_service.dart` → `usp_client.dart`

### 階段 2：核心檔案重新命名
4. ✅ **重新命名主服務檔案**
   - `lib/core/usp/services/usp_service.dart` → `usp_client.dart`
   - 更新檔案內部類別名稱：`UspService` → `UspClient`

5. ✅ **重新命名 Provider 檔案**
   - `lib/core/usp/providers/usp_service_provider.dart` → `usp_client_provider.dart`
   - 更新 Provider 變數名稱：`uspServiceProvider` → `uspClientProvider`

### 階段 3：重新生成程式碼
6. ✅ **執行 codegen**
   ```bash
   ./tools/usp-codegen --definitions-dir definitions/ \
     --output-dir lib/generated/ --language dart \
     --client-import 'package:privacy_gui/usp/services/usp_client.dart'
   ```

### 階段 4：更新相依性
7. ✅ **更新所有 Provider 匯入**（53個檔案）
   - 將所有 `uspServiceProvider` 替換為 `uspClientProvider`
   - 將匯入路徑從 `usp_service.dart` 更新為 `usp_client.dart`

8. ✅ **更新其餘類別參考**（107個檔案）
   - 將所有 `UspService` 類別參考替換為 `UspClient`
   - 更新建構函式和方法參數型別

### 階段 5：文件和測試更新
9. ✅ **更新文件檔案**
   - 所有文件中的 `UspService` 參考更新為 `UspClient`

10. ✅ **更新測試檔案**
    - 測試中的 mock 和參考更新

11. ✅ **更新 Demo 資料**
    - JSON 檔案中的相關參考

## 執行順序的重要性

### 為什麼必須按順序執行？

1. **Codegen 相依性**：
   - Codegen 工具依賴 CLI 參數中的類別名稱和匯入路徑
   - 必須先更新這些參數才能重新生成正確的程式碼

2. **匯入路徑一致性**：
   - 27個自動生成檔案會使用新的匯入路徑
   - 核心檔案必須先重新命名，確保匯入路徑有效

3. **編譯錯誤最小化**：
   - 按順序更新可以避免大範圍的編譯錯誤
   - 每個階段完成後都能保持程式碼可編譯狀態

## 風險評估

### 高風險項目
- **Codegen 重新生成**：可能會覆蓋任何手動修改
- **Provider 鏈式相依**：錯誤更新可能導致整個模組無法使用

### 緩解措施
- **Git 分支**：在專用分支進行重構
- **階段性提交**：每個階段完成後立即提交
- **測試驗證**：每階段後執行相關測試

## 完成後的驗證

### 編譯檢查
```bash
flutter analyze
flutter build web --no-web-resources-cdn
```

### 功能測試
```bash
./run_tests.sh
flutter test --tags ui
```

### USP 集成測試
```bash
flutter test test/core/usp/integration/codegen_verification_test.dart
```

## 預期效果

### 命名清晰度
- ✅ **UspClient**: USP 協議通信、傳輸層
- ✅ **xxxService**: 業務邏輯、錯誤處理  
- ✅ **xxxProvider**: 狀態管理、UI 邏輯

### 架構一致性
- ✅ 職責邊界清楚
- ✅ 後續 Service 層實作不會有命名衝突
- ✅ 符合 `doc/architecture/usp-naming-refactor.md` 架構設計

---

**文件版本**: v1.0  
**建立日期**: 2026-04-10  
**預計執行時間**: 2-3小時  
**負責人**: Austin Chang