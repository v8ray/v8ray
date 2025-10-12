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
  String get paste => 'Paste';

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
}
