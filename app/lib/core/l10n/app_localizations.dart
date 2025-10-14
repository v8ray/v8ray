import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'V8Ray'**
  String get appName;

  /// Error title when admin privileges are required
  ///
  /// In en, this message translates to:
  /// **'Administrator Privileges Required'**
  String get errorAdminPrivilegesRequired;

  /// Error message when admin privileges are required
  ///
  /// In en, this message translates to:
  /// **'V8Ray requires administrator/root privileges to manage system proxy settings.\n\nPlease run the application with administrator privileges:\n• Linux/macOS: sudo ./v8ray\n• Windows: Right-click and select \"Run as administrator\"'**
  String get errorAdminPrivilegesMessage;

  /// Error title when initialization fails
  ///
  /// In en, this message translates to:
  /// **'Initialization Failed'**
  String get errorInitializationFailed;

  /// Error title when permission check fails
  ///
  /// In en, this message translates to:
  /// **'Permission Check Failed'**
  String get errorPermissionCheckFailed;

  /// Exit button
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Simple mode label
  ///
  /// In en, this message translates to:
  /// **'Simple Mode'**
  String get simpleMode;

  /// Advanced mode label
  ///
  /// In en, this message translates to:
  /// **'Advanced Mode'**
  String get advancedMode;

  /// Connect button
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Disconnect button
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Connection status label
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get connectionStatus;

  /// Connected status
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Connecting status
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// Disconnected status
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// Disconnecting status
  ///
  /// In en, this message translates to:
  /// **'Disconnecting'**
  String get disconnecting;

  /// Error status
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Subscription URL input label
  ///
  /// In en, this message translates to:
  /// **'Subscription URL'**
  String get subscriptionUrl;

  /// Subscription URL input hint
  ///
  /// In en, this message translates to:
  /// **'Paste your subscription URL here'**
  String get subscriptionUrlHint;

  /// Update subscription button
  ///
  /// In en, this message translates to:
  /// **'Update Subscription'**
  String get updateSubscription;

  /// Add subscription button
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get addSubscription;

  /// Proxy mode label
  ///
  /// In en, this message translates to:
  /// **'Proxy Mode'**
  String get proxyMode;

  /// Global proxy mode
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get globalMode;

  /// Smart routing mode
  ///
  /// In en, this message translates to:
  /// **'Smart Routing'**
  String get smartMode;

  /// Direct connection mode
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get directMode;

  /// Current node label
  ///
  /// In en, this message translates to:
  /// **'Current Node'**
  String get currentNode;

  /// Latency label
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get latency;

  /// Speed label
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// Upload speed label
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadSpeed;

  /// Download speed label
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadSpeed;

  /// Settings menu
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// System theme
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// About menu
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Check update button
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkUpdate;

  /// Switch to simple mode button
  ///
  /// In en, this message translates to:
  /// **'Switch to Simple Mode'**
  String get switchToSimpleMode;

  /// Switch to advanced mode button
  ///
  /// In en, this message translates to:
  /// **'Switch to Advanced Mode'**
  String get switchToAdvancedMode;

  /// Invalid URL error message
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// Empty URL error message
  ///
  /// In en, this message translates to:
  /// **'Please enter a subscription URL'**
  String get pleaseEnterUrl;

  /// Update success message
  ///
  /// In en, this message translates to:
  /// **'Update successful'**
  String get updateSuccess;

  /// Update failed message
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// Connect success message
  ///
  /// In en, this message translates to:
  /// **'Connected successfully'**
  String get connectSuccess;

  /// Connect failed message
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectFailed;

  /// Disconnect success message
  ///
  /// In en, this message translates to:
  /// **'Disconnected successfully'**
  String get disconnectSuccess;

  /// No available node error
  ///
  /// In en, this message translates to:
  /// **'No available node'**
  String get noAvailableNode;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Clear button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// More information button
  ///
  /// In en, this message translates to:
  /// **'More Info'**
  String get moreInfo;

  /// Paste button
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Warning when app is not running as admin
  ///
  /// In en, this message translates to:
  /// **'Not running with administrator privileges'**
  String get noAdminPrivileges;

  /// Hint for running as administrator
  ///
  /// In en, this message translates to:
  /// **'System proxy settings may require administrator privileges. If you encounter issues, please restart the application as administrator.'**
  String get noAdminPrivilegesHint;

  /// Dialog title for admin privileges
  ///
  /// In en, this message translates to:
  /// **'Administrator Privileges Required'**
  String get adminPrivilegesRequired;

  /// Explanation of why admin privileges are needed
  ///
  /// In en, this message translates to:
  /// **'Modifying system proxy settings typically requires administrator privileges. If you encounter permission errors when enabling system proxy, please follow the instructions below to run the application as administrator.'**
  String get adminPrivilegesExplanation;

  /// Section title for admin instructions
  ///
  /// In en, this message translates to:
  /// **'How to Run as Administrator'**
  String get howToRunAsAdmin;

  /// Instructions for Windows
  ///
  /// In en, this message translates to:
  /// **'Right-click the application icon and select \'Run as administrator\''**
  String get windowsAdminInstructions;

  /// Instructions for macOS
  ///
  /// In en, this message translates to:
  /// **'Run with sudo command in Terminal, or grant permissions in System Preferences'**
  String get macosAdminInstructions;

  /// Instructions for Linux
  ///
  /// In en, this message translates to:
  /// **'Run with sudo command, or add user to appropriate permission groups'**
  String get linuxAdminInstructions;

  /// Global mode description
  ///
  /// In en, this message translates to:
  /// **'All traffic goes through proxy'**
  String get globalModeDescription;

  /// Smart mode description
  ///
  /// In en, this message translates to:
  /// **'Foreign sites use proxy, domestic sites direct'**
  String get smartModeDescription;

  /// Direct mode description
  ///
  /// In en, this message translates to:
  /// **'All traffic goes direct'**
  String get directModeDescription;

  /// Subscription configuration button
  ///
  /// In en, this message translates to:
  /// **'Subscription Config'**
  String get subscriptionConfig;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Save success message
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saveSuccess;

  /// Node selection label
  ///
  /// In en, this message translates to:
  /// **'Node Selection'**
  String get nodeSelection;

  /// Select node button
  ///
  /// In en, this message translates to:
  /// **'Select Node'**
  String get selectNode;

  /// Please select node error message
  ///
  /// In en, this message translates to:
  /// **'Please select a node first'**
  String get pleaseSelectNode;

  /// No servers available message
  ///
  /// In en, this message translates to:
  /// **'No servers available'**
  String get noServersAvailable;

  /// Please update subscription hint
  ///
  /// In en, this message translates to:
  /// **'Please update subscription to get servers'**
  String get pleaseUpdateSubscription;

  /// Total servers label
  ///
  /// In en, this message translates to:
  /// **'Total Servers'**
  String get totalServers;

  /// Refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Change button
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Unknown error message
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// Network error title
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// Network timeout error message
  ///
  /// In en, this message translates to:
  /// **'Network request timed out. Please check your internet connection and try again.'**
  String get networkTimeoutError;

  /// DNS resolution error message
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve domain name. Please check your DNS settings.'**
  String get dnsResolutionError;

  /// Connection refused error message
  ///
  /// In en, this message translates to:
  /// **'Connection refused. The server may be down or unreachable.'**
  String get connectionRefusedError;

  /// No internet error message
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network settings.'**
  String get noInternetError;

  /// SSL certificate error message
  ///
  /// In en, this message translates to:
  /// **'SSL certificate verification failed. The connection may not be secure.'**
  String get sslCertificateError;

  /// Subscription error title
  ///
  /// In en, this message translates to:
  /// **'Subscription Error'**
  String get subscriptionError;

  /// Invalid subscription URL error message
  ///
  /// In en, this message translates to:
  /// **'Invalid subscription URL. Please check the URL and try again.'**
  String get invalidSubscriptionUrl;

  /// Subscription parse error message
  ///
  /// In en, this message translates to:
  /// **'Failed to parse subscription data. The subscription format may be incorrect.'**
  String get subscriptionParseError;

  /// Empty subscription error message
  ///
  /// In en, this message translates to:
  /// **'No servers found in subscription. Please check the subscription URL.'**
  String get emptySubscriptionError;

  /// Subscription not found error message
  ///
  /// In en, this message translates to:
  /// **'Subscription not found. The URL may be incorrect or expired.'**
  String get subscriptionNotFoundError;

  /// Subscription unauthorized error message
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access to subscription. Please check your credentials.'**
  String get subscriptionUnauthorizedError;

  /// Connection error title
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// Connection timeout error message
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please try again.'**
  String get connectionTimeoutError;

  /// No server selected error message
  ///
  /// In en, this message translates to:
  /// **'No server selected. Please select a server first.'**
  String get noServerSelectedError;

  /// Already connected error message
  ///
  /// In en, this message translates to:
  /// **'Already connected. Please disconnect first.'**
  String get alreadyConnectedError;

  /// Not connected error message
  ///
  /// In en, this message translates to:
  /// **'Not connected. Please connect first.'**
  String get notConnectedError;

  /// Configuration error title
  ///
  /// In en, this message translates to:
  /// **'Configuration Error'**
  String get configError;

  /// Invalid config error message
  ///
  /// In en, this message translates to:
  /// **'Invalid configuration. Please check your settings.'**
  String get invalidConfigError;

  /// Missing config error message
  ///
  /// In en, this message translates to:
  /// **'Missing required configuration. Please complete your settings.'**
  String get missingConfigError;

  /// Permission error title
  ///
  /// In en, this message translates to:
  /// **'Permission Error'**
  String get permissionError;

  /// VPN permission error message
  ///
  /// In en, this message translates to:
  /// **'VPN permission denied. Please grant VPN permission in system settings.'**
  String get vpnPermissionError;

  /// Network permission error message
  ///
  /// In en, this message translates to:
  /// **'Network permission denied. Please grant network permission.'**
  String get networkPermissionError;

  /// Storage permission error message
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied. Please grant storage permission.'**
  String get storagePermissionError;

  /// Network error suggestion
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get networkErrorSuggestion;

  /// Subscription error suggestion
  ///
  /// In en, this message translates to:
  /// **'Please verify the subscription URL and try updating again.'**
  String get subscriptionErrorSuggestion;

  /// Connection error suggestion
  ///
  /// In en, this message translates to:
  /// **'Please check your server settings and network connection.'**
  String get connectionErrorSuggestion;

  /// Permission error suggestion
  ///
  /// In en, this message translates to:
  /// **'Please grant the required permissions in system settings.'**
  String get permissionErrorSuggestion;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Retrying status text
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get retrying;

  /// Retry countdown text
  ///
  /// In en, this message translates to:
  /// **'Retry in {seconds}s'**
  String retryIn(int seconds);

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Please wait text
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// Operation in progress text
  ///
  /// In en, this message translates to:
  /// **'Operation in progress...'**
  String get operationInProgress;

  /// System proxy title
  ///
  /// In en, this message translates to:
  /// **'System Proxy'**
  String get systemProxy;

  /// Proxy settings title
  ///
  /// In en, this message translates to:
  /// **'Proxy Settings'**
  String get proxySettings;

  /// System proxy enabled status
  ///
  /// In en, this message translates to:
  /// **'System proxy is enabled'**
  String get systemProxyEnabled;

  /// System proxy disabled status
  ///
  /// In en, this message translates to:
  /// **'System proxy is disabled'**
  String get systemProxyDisabled;

  /// System proxy enabled success message
  ///
  /// In en, this message translates to:
  /// **'System proxy enabled successfully'**
  String get systemProxyEnabledSuccess;

  /// System proxy disabled success message
  ///
  /// In en, this message translates to:
  /// **'System proxy disabled successfully'**
  String get systemProxyDisabledSuccess;

  /// System proxy error message
  ///
  /// In en, this message translates to:
  /// **'Failed to change system proxy settings'**
  String get systemProxyError;

  /// Auto set system proxy option
  ///
  /// In en, this message translates to:
  /// **'Auto set system proxy'**
  String get autoSetSystemProxy;

  /// Auto set system proxy description
  ///
  /// In en, this message translates to:
  /// **'Automatically set system proxy when connected'**
  String get autoSetSystemProxyDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
