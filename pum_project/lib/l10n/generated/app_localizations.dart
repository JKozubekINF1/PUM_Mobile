import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('pl'),
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appTitle;

  /// No description provided for @loginPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginPageTitle;

  /// No description provided for @registerPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerPageTitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get confirmPasswordLabel;

  /// No description provided for @forgotPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLabel;

  /// No description provided for @registerDuringLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get registerDuringLoginLabel;

  /// No description provided for @loginDuringRegisterLabel.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get loginDuringRegisterLabel;

  /// No description provided for @loginButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButtonLabel;

  /// No description provided for @registerButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButtonLabel;

  /// No description provided for @loginSuccessfulMessage.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get loginSuccessfulMessage;

  /// No description provided for @registerSuccessfulMessage.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registerSuccessfulMessage;

  /// No description provided for @emptyFieldMessage.
  ///
  /// In en, this message translates to:
  /// **'Fill out all required fields'**
  String get emptyFieldMessage;

  /// No description provided for @badLoginMessage.
  ///
  /// In en, this message translates to:
  /// **'Incorrect login credentials'**
  String get badLoginMessage;

  /// No description provided for @emailTakenMessage.
  ///
  /// In en, this message translates to:
  /// **'Email is already taken'**
  String get emailTakenMessage;

  /// No description provided for @incorrectEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email'**
  String get incorrectEmailMessage;

  /// No description provided for @incorrectPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPasswordMessage;

  /// No description provided for @failedToRepeatPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to repeat password'**
  String get failedToRepeatPasswordMessage;

  /// No description provided for @noConnectionMessage.
  ///
  /// In en, this message translates to:
  /// **'Lost connection to the server, check your internet connection'**
  String get noConnectionMessage;

  /// No description provided for @genericErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred, try again later'**
  String get genericErrorMessage;
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
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
