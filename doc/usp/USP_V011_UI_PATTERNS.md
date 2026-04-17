# USP v0.11.0 UI Pattern Guide

## 部分成功的 UI 處理模式

### 方案A: 詳細狀態通知 (推薦)

```dart
// WiFi 設定結果處理
Widget _handleWiFiSettingsResult(UspSetResult result) {
  return switch (result) {
    UspSuccess() => SuccessSnackBar('WiFi 設定已儲存'),
    
    UspPartialSuccess(successes: final successes, failures: final failures) =>
      DetailedResultDialog(
        title: '部分設定已儲存',
        successes: successes.map((s) => _getDisplayName(s.requestedPath)).toList(),
        failures: failures.map((f) => 
          FailureItem(
            name: _getDisplayName(f.requestedPath),
            error: _getUserFriendlyError(f.errorCode, f.errorMessage),
            canRetry: f.isRetryable,
          )
        ).toList(),
        onRetryFailures: () => _retryFailedSettings(failures),
      ),
      
    UspFailure(errors: final errors) => 
      ErrorDialog('設定儲存失敗', _summarizeErrors(errors)),
  };
}

String _getDisplayName(String path) {
  return switch (path) {
    'Device.WiFi.SSID.1.SSID' => '網路名稱',
    'Device.WiFi.SSID.1.Enable' => '網路啟用狀態',
    'Device.WiFi.AccessPoint.1.Security.ModeEnabled' => '安全模式',
    'Device.WiFi.AccessPoint.1.MaxAssociations' => '最大連接數',
    _ => path.split('.').last,
  };
}
```

### 方案B: 簡化通知 + 詳細頁面

```dart
Widget _handleSimplified(UspSetResult result) {
  return switch (result) {
    UspSuccess() => 
      SuccessSnackBar('設定已儲存'),
      
    UspPartialSuccess() => Column(children: [
      WarningSnackBar('部分設定已儲存，點擊查看詳細'),
      DetailButton(onTap: () => _showDetailedResults(result)),
    ]),
    
    UspFailure() => 
      ErrorSnackBar('設定儲存失敗，點擊查看詳細'),
  };
}
```

### 方案C: 內聯狀態顯示

```dart
// 在設定表單中直接顯示每個欄位的狀態
class WiFiSettingsForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextFormField(
        decoration: InputDecoration(
          labelText: '網路名稱',
          suffixIcon: _buildStatusIcon('Device.WiFi.SSID.1.SSID'),
          errorText: _getFieldError('Device.WiFi.SSID.1.SSID'),
        ),
      ),
      
      SwitchListTile(
        title: Text('啟用網路'),
        trailing: _buildStatusIcon('Device.WiFi.SSID.1.Enable'),
        subtitle: _getFieldError('Device.WiFi.SSID.1.Enable') != null 
          ? Text(_getFieldError('Device.WiFi.SSID.1.Enable')!)
          : null,
      ),
    ]);
  }
  
  Widget _buildStatusIcon(String path) {
    final status = _getFieldStatus(path);
    return switch (status) {
      FieldStatus.success => Icon(Icons.check_circle, color: Colors.green),
      FieldStatus.error => Icon(Icons.error, color: Colors.red),
      FieldStatus.loading => CircularProgressIndicator(),
      _ => SizedBox.shrink(),
    };
  }
}
```