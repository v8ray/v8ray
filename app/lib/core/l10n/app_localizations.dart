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
    Locale('zh')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'V8Ray'**
  String get appName;

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

  /// Paste button
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

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
      'that was used.');
}
