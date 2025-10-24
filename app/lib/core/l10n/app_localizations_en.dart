// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'V8Ray';

  @override
  String get errorAdminPrivilegesRequired =>
      'Administrator Privileges Required';

  @override
  String get errorAdminPrivilegesMessage =>
      'V8Ray requires administrator/root privileges to manage system proxy settings.\n\nPlease run the application with administrator privileges:\n• Linux/macOS: sudo ./v8ray\n• Windows: Right-click and select \"Run as administrator\"';

  @override
  String get errorInitializationFailed => 'Initialization Failed';

  @override
  String get errorPermissionCheckFailed => 'Permission Check Failed';

  @override
  String get exit => 'Exit';

  @override
  String get simpleMode => 'Simple Mode';

  @override
  String get advancedMode => 'Advanced Mode';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connectionStatus => 'Connection Status';

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get disconnecting => 'Disconnecting';

  @override
  String get error => 'Error';

  @override
  String get subscriptionUrl => 'Subscription URL';

  @override
  String get subscriptionUrlHint => 'Paste your subscription URL here';

  @override
  String get updateSubscription => 'Update Subscription';

  @override
  String get addSubscription => 'Add Subscription';

  @override
  String get proxyMode => 'Proxy Mode';

  @override
  String get globalMode => 'Global';

  @override
  String get smartMode => 'Smart Routing';

  @override
  String get directMode => 'Direct';

  @override
  String get currentNode => 'Current Node';

  @override
  String get latency => 'Latency';

  @override
  String get testLatency => 'Test Latency';

  @override
  String get speed => 'Speed';

  @override
  String get uploadSpeed => 'Upload';

  @override
  String get downloadSpeed => 'Download';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get checkUpdate => 'Check for Updates';

  @override
  String get currentVersion => 'Current Version';

  @override
  String get latestVersion => 'Latest Version';

  @override
  String get checkingUpdate => 'Checking for updates...';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get noUpdateAvailable => 'You\'re up to date';

  @override
  String get downloadUpdate => 'Download Update';

  @override
  String get downloading => 'Downloading...';

  @override
  String get downloadProgress => 'Download Progress';

  @override
  String get updateDownloaded => 'Update Downloaded';

  @override
  String get installUpdate => 'Install Update';

  @override
  String get restartToUpdate => 'Restart to Update';

  @override
  String get updateInstalled => 'Update Installed';

  @override
  String get restartToApplyUpdate =>
      'The update has been successfully installed. Please restart the application to apply the update.';

  @override
  String get restartNow => 'Restart Now';

  @override
  String get updateInstallFailed => 'Failed to Install Update';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get close => 'Close';

  @override
  String get updateCheckFailed => 'Failed to check for updates';

  @override
  String get updateDownloadFailed => 'Failed to download update';

  @override
  String newVersionAvailable(String version) {
    return 'New version $version is available';
  }

  @override
  String get updateNow => 'Update Now';

  @override
  String get later => 'Later';

  @override
  String get releaseNotes => 'Release Notes';

  @override
  String get switchToSimpleMode => 'Switch to Simple Mode';

  @override
  String get switchToAdvancedMode => 'Switch to Advanced Mode';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get pleaseEnterUrl => 'Please enter a subscription URL';

  @override
  String get updateSuccess => 'Update successful';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get connectSuccess => 'Connected successfully';

  @override
  String get connectFailed => 'Connection failed';

  @override
  String get disconnectSuccess => 'Disconnected successfully';

  @override
  String get noAvailableNode => 'No available node';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get clear => 'Clear';

  @override
  String get moreInfo => 'More Info';

  @override
  String get paste => 'Paste';

  @override
  String get noAdminPrivileges => 'Not running with administrator privileges';

  @override
  String get noAdminPrivilegesHint =>
      'System proxy settings may require administrator privileges. If you encounter issues, please restart the application as administrator.';

  @override
  String get adminPrivilegesRequired => 'Administrator Privileges Required';

  @override
  String get adminPrivilegesExplanation =>
      'Modifying system proxy settings typically requires administrator privileges. If you encounter permission errors when enabling system proxy, please follow the instructions below to run the application as administrator.';

  @override
  String get howToRunAsAdmin => 'How to Run as Administrator';

  @override
  String get windowsAdminInstructions =>
      'Right-click the application icon and select \'Run as administrator\'';

  @override
  String get macosAdminInstructions =>
      'Run with sudo command in Terminal, or grant permissions in System Preferences';

  @override
  String get linuxAdminInstructions =>
      'Run with sudo command, or add user to appropriate permission groups';

  @override
  String get globalModeDescription => 'All traffic goes through proxy';

  @override
  String get smartModeDescription =>
      'Foreign sites use proxy, domestic sites direct';

  @override
  String get directModeDescription => 'All traffic goes direct';

  @override
  String get subscriptionConfig => 'Subscription Config';

  @override
  String get save => 'Save';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String get nodeSelection => 'Node Selection';

  @override
  String get selectNode => 'Select Node';

  @override
  String get pleaseSelectNode => 'Please select a node first';

  @override
  String get noServersAvailable => 'No servers available';

  @override
  String get pleaseUpdateSubscription =>
      'Please update subscription to get servers';

  @override
  String get totalServers => 'Total Servers';

  @override
  String get refresh => 'Refresh';

  @override
  String get change => 'Change';

  @override
  String get networkError => 'Network Error';

  @override
  String get networkTimeoutError =>
      'Network request timed out. Please check your internet connection and try again.';

  @override
  String get dnsResolutionError =>
      'Failed to resolve domain name. Please check your DNS settings.';

  @override
  String get connectionRefusedError =>
      'Connection refused. The server may be down or unreachable.';

  @override
  String get noInternetError =>
      'No internet connection. Please check your network settings.';

  @override
  String get sslCertificateError =>
      'SSL certificate verification failed. The connection may not be secure.';

  @override
  String get subscriptionError => 'Subscription Error';

  @override
  String get invalidSubscriptionUrl =>
      'Invalid subscription URL. Please check the URL and try again.';

  @override
  String get subscriptionParseError =>
      'Failed to parse subscription data. The subscription format may be incorrect.';

  @override
  String get emptySubscriptionError =>
      'No servers found in subscription. Please check the subscription URL.';

  @override
  String get subscriptionNotFoundError =>
      'Subscription not found. The URL may be incorrect or expired.';

  @override
  String get subscriptionUnauthorizedError =>
      'Unauthorized access to subscription. Please check your credentials.';

  @override
  String get connectionError => 'Connection Error';

  @override
  String get connectionTimeoutError =>
      'Connection timed out. Please try again.';

  @override
  String get noServerSelectedError =>
      'No server selected. Please select a server first.';

  @override
  String get alreadyConnectedError =>
      'Already connected. Please disconnect first.';

  @override
  String get notConnectedError => 'Not connected. Please connect first.';

  @override
  String get configError => 'Configuration Error';

  @override
  String get invalidConfigError =>
      'Invalid configuration. Please check your settings.';

  @override
  String get missingConfigError =>
      'Missing required configuration. Please complete your settings.';

  @override
  String get permissionError => 'Permission Error';

  @override
  String get vpnPermissionError =>
      'VPN permission denied. Please grant VPN permission in system settings.';

  @override
  String get networkPermissionError =>
      'Network permission denied. Please grant network permission.';

  @override
  String get storagePermissionError =>
      'Storage permission denied. Please grant storage permission.';

  @override
  String get networkErrorSuggestion =>
      'Please check your internet connection and try again.';

  @override
  String get subscriptionErrorSuggestion =>
      'Please verify the subscription URL and try updating again.';

  @override
  String get connectionErrorSuggestion =>
      'Please check your server settings and network connection.';

  @override
  String get permissionErrorSuggestion =>
      'Please grant the required permissions in system settings.';

  @override
  String get retry => 'Retry';

  @override
  String get retrying => 'Retrying...';

  @override
  String retryIn(int seconds) {
    return 'Retry in ${seconds}s';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get operationInProgress => 'Operation in progress...';

  @override
  String get systemProxy => 'System Proxy';

  @override
  String get proxySettings => 'Proxy Settings';

  @override
  String get systemProxyEnabled => 'System proxy is enabled';

  @override
  String get systemProxyDisabled => 'System proxy is disabled';

  @override
  String get systemProxyEnabledSuccess => 'System proxy enabled successfully';

  @override
  String get systemProxyDisabledSuccess => 'System proxy disabled successfully';

  @override
  String get systemProxyError => 'Failed to change system proxy settings';

  @override
  String get autoSetSystemProxy => 'Auto set system proxy';

  @override
  String get autoSetSystemProxyDescription =>
      'Automatically set system proxy when connected';

  @override
  String get disconnectToChangeProxyMode =>
      'Please disconnect first to change proxy mode';

  @override
  String get xrayCoreVersion => 'Xray Core Version';

  @override
  String get xrayCoreCurrentVersion => 'Current Xray Core';

  @override
  String get xrayCoreLatestVersion => 'Latest Xray Core';

  @override
  String get checkingXrayCoreUpdate => 'Checking Xray Core update...';

  @override
  String get xrayCoreUpdateAvailable => 'Xray Core Update Available';

  @override
  String get noXrayCoreUpdateAvailable => 'Xray Core is up to date';

  @override
  String get downloadXrayCoreUpdate => 'Download Xray Core Update';

  @override
  String get downloadingXrayCore => 'Downloading Xray Core...';

  @override
  String get xrayCoreUpdateDownloaded => 'Xray Core Update Downloaded';

  @override
  String get installXrayCoreUpdate => 'Install Xray Core Update';

  @override
  String get xrayCoreUpdateCheckFailed => 'Failed to check Xray Core update';

  @override
  String get xrayCoreUpdateDownloadFailed =>
      'Failed to download Xray Core update';

  @override
  String newXrayCoreVersionAvailable(String version) {
    return 'New Xray Core version $version is available';
  }

  @override
  String get xrayCoreNotInstalled => 'Xray Core not installed';

  @override
  String get checkXrayCoreUpdate => 'Check Xray Core Update';

  @override
  String get xrayCoreUpdateInstalled => 'Xray Core updated successfully';

  @override
  String get xrayCoreUpdateInstallFailed =>
      'Failed to install Xray Core update';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get nodes => 'Nodes';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get logs => 'Logs';

  @override
  String get connectionInfo => 'Connection Info';

  @override
  String get currentNodeInfo => 'Current Node';

  @override
  String get proxyModeInfo => 'Proxy Mode';

  @override
  String get systemStatus => 'System Status';

  @override
  String get trafficStatistics => 'Traffic Statistics';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get switchNode => 'Switch Node';

  @override
  String get nodeManagement => 'Node Management';

  @override
  String get subscriptionManagement => 'Subscription Management';

  @override
  String get search => 'Search';

  @override
  String get addNode => 'Add Node';

  @override
  String get sortBy => 'Sort by';

  @override
  String get filterBy => 'Filter by';

  @override
  String get groupBy => 'Group by';

  @override
  String get all => 'All';

  @override
  String get available => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get test => 'Test';

  @override
  String get subscriptionList => 'Subscription List';

  @override
  String get subscriptionSettings => 'Subscription Settings';

  @override
  String get autoUpdateInterval => 'Auto Update Interval';

  @override
  String get retryOnFailure => 'Retry on Failure';

  @override
  String get nodeFilterRules => 'Node Filter Rules';

  @override
  String get lastUpdate => 'Last Update';

  @override
  String get nodeCount => 'Node Count';

  @override
  String get autoUpdate => 'Auto Update';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get logLevel => 'Log Level';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get basicSettings => 'Basic Settings';

  @override
  String get routingRules => 'Routing Rules';

  @override
  String get dnsSettings => 'DNS Settings';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get startOnBoot => 'Start on Boot';

  @override
  String get minimizeToTray => 'Minimize to Tray';

  @override
  String get autoConnect => 'Auto Connect';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get connectionStatusChange => 'Connection Status Change';

  @override
  String get subscriptionUpdate => 'Subscription Update';

  @override
  String get errorNotification => 'Error Notification';

  @override
  String get localPort => 'Local Port';

  @override
  String get allowLan => 'Allow LAN';

  @override
  String get httpProxy => 'HTTP Proxy';

  @override
  String get httpsProxy => 'HTTPS Proxy';

  @override
  String get pacMode => 'PAC Mode';

  @override
  String get tunMode => 'TUN Mode';

  @override
  String get tunDevice => 'TUN Device';

  @override
  String get tunNetwork => 'TUN Network';

  @override
  String get running => 'Running';

  @override
  String get stopped => 'Stopped';

  @override
  String get normal => 'Normal';

  @override
  String get totalUpload => 'Total Upload';

  @override
  String get totalDownload => 'Total Download';

  @override
  String get connectionDuration => 'Connection Duration';

  @override
  String get hours => 'hours';

  @override
  String get minutes => 'minutes';

  @override
  String get seconds => 'seconds';

  @override
  String get never => 'Never';

  @override
  String get pleaseAddSubscription => 'Please add a subscription first';

  @override
  String get noSubscriptions => 'No subscriptions';
}
