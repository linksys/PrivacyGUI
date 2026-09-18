// Share Preferences keys, please check is there any data need to be removed when log out
// unsecured
const pCloudEnv = 'CloudEnvironment';
const pCurrentSN = 'LinksysCurrentSN';
const pDeviceToken = 'LinksysDeviceToken';
const pSmartDeviceId = 'LinksysSmartDeviceId';
const pSmartDeviceSecret = 'LinksysSmartDeviceSecret';
const pSmartDeviceVerified = 'LinksysSmartDeviceVerified';

const pSelectedNetworkId = 'LinksysSelectedNetworkId';
const pShowPushPrompt = 'PushPrompt';
const pAppFirstLaunch = 'AppFirstLaunch';
const pWebLog = 'web_log';
const pRedirection = 'Redirection';
const pBlinkingNodeId = 'BlinkingNodeId';

const pNotificationLastSeen = 'NotificationLastSeen';
const pNotifications = 'Notifications';

const pPnpConfiguredSN = "PnPLinksysSN";
const pPnpSetup = "PnPSetup";

const pAppSettings = "AppSettings";

const pFWUpdated = 'FwUpdated';

// USP Dashboard
const pUspLayoutPreferences = 'usp_layout_preferences';
const pUspPresetDialogSeen = 'usp_preset_dialog_seen';
const pUspSliverDashboardLayout = 'usp_sliver_dashboard_layout';

// secured
const pSessionToken = 'SessionToken';
const pSessionTokenTs = 'SessionTokenTimeStamp';
const pUserPassword = 'UserPassword';
const pUsername = 'Username';
const pBiometrics = 'Biometrics';
const pLinksysToken = 'LinksysToken';
const pLinksysTokenTs = 'LinksysTokenTs';

/// The serial number the cached [pLinksysToken] was issued for.
///
/// Without it the cache is keyed on nothing but time, so swapping the router
/// behind the same LAN address hands the new device the previous device's token
/// — see `GuardianApiClient.fetchDeviceToken` (PrivacyGUI#1582).
const pLinksysTokenSn = 'LinksysTokenSn';
