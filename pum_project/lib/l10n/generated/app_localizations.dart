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

  /// Full name of the language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// Name of the app
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appTitle;

  /// Title of welcome page that usually appears on the app bar
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get firstVisitPageTitle;

  /// Title of login page that usually appears on the app bar
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginPageTitle;

  /// Title of register page that usually appears on the app bar
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerPageTitle;

  /// Title of home page that usually appears on the app bar
  ///
  /// In en, this message translates to:
  /// **'Homepage'**
  String get homePageTitle;

  /// Title of map page that usually appears on the app bar
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get trackPageTitle;

  /// Title of map page that usually appears on the app bar
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultPageTitle;

  /// Title of profile page that usually appears on the app bar
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get profilePageTitle;

  /// Title of settings page that usually appears on the app bar
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsPageTitle;

  /// Label text that appears on a popup window before warning the user
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warningLabel;

  /// Label text for the accept button during prompts
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get acceptOptionLabel;

  /// Label text for the decline button during prompts
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineOptionLabel;

  /// Label text for the username text field
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Label text for the email text field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Label text for the password text field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Label text for the repeat password text field
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get confirmPasswordLabel;

  /// Label text for a hyperlink to the reset password page
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLabel;

  /// Label text for a hyperlink to the register page that appears on the login page
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get registerDuringLoginLabel;

  /// Label text for a hyperlink to the login page that appears on the register page
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get loginDuringRegisterLabel;

  /// Label text for a hyperlink to the login page
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButtonLabel;

  /// Label text for a hyperlink to the register page
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButtonLabel;

  /// Label text for a logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButtonLabel;

  /// Label text for a hyperlink to the profile page
  ///
  /// In en, this message translates to:
  /// **'Show Profile'**
  String get profileButtonLabel;

  /// Label text for a hyperlink to the app settings page
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsButtonLabel;

  /// Label text for an option that opens the app in offline mode
  ///
  /// In en, this message translates to:
  /// **'or open in offline mode'**
  String get offlineModeTextLabel;

  /// Label text for the first name text field
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get profileFirstNameLabel;

  /// Label text for the last name text field
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get profileLastNameLabel;

  /// Label text for the gender dropdown menu
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGenderLabel;

  /// Label text for the user date of birth
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileDayOfBirthLabel;

  /// Label text that appears as a part of optional options
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalLabel;

  /// Label text for the male gender option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileGenderMaleLabel;

  /// Label text for the female gender option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileGenderFemaleLabel;

  /// Label text for the other gender option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileGenderOtherLabel;

  /// Label text for the user height
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeightLabel;

  /// Label text for the user weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profileWeightLabel;

  /// Label text for choosing the user profile picture
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profileAvatarLabel;

  /// Label text for the save changes button
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesLabel;

  /// Label text for the start activity button
  ///
  /// In en, this message translates to:
  /// **'START ACTIVITY'**
  String get beginActivityButtonLabel;

  /// Label text for the stop activity button
  ///
  /// In en, this message translates to:
  /// **'STOP ACTIVITY'**
  String get stopActivityButtonLabel;

  /// Label text for the language setting
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageLabel;

  /// Message that appears on the first visit page, prompting the user to login or create an account
  ///
  /// In en, this message translates to:
  /// **'Log in or create a new account'**
  String get welcomeNewUserMessage;

  /// Message that appears on the first visit page, warning the user of the limitations of the offline mode
  ///
  /// In en, this message translates to:
  /// **'Some app features are unavailable in offline mode. Are you sure you want to proceed?'**
  String get offlineModeWarningMessage;

  /// Message that appears when the user interacts with the logout button, making sure he wants to log out
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutWarningMessage;

  /// Message that appears on the login page after a successful login
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get loginSuccessfulMessage;

  /// Message that appears on the register page after a successful registration
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registerSuccessfulMessage;

  /// Message that appears after a successful logout
  ///
  /// In en, this message translates to:
  /// **'You have been logged out'**
  String get logoutSuccessfulMessage;

  /// Message that appears after a failure of not filling out all required fields
  ///
  /// In en, this message translates to:
  /// **'Fill out all required fields'**
  String get emptyFieldMessage;

  /// Message that appears after a failure of filling out incorrect credentials on the login page
  ///
  /// In en, this message translates to:
  /// **'Incorrect login credentials'**
  String get badLoginMessage;

  /// Message that appears after a failure of submitting an already taken email
  ///
  /// In en, this message translates to:
  /// **'Email is already taken'**
  String get emailTakenMessage;

  /// Message that appears after a failure of submitting an incorrect email on the register page
  ///
  /// In en, this message translates to:
  /// **'Incorrect email'**
  String get incorrectEmailMessage;

  /// Message that appears after a failure of submitting an incorrect password on the register page
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPasswordMessage;

  /// Message that appears after a failure of not repeating the password on the register page
  ///
  /// In en, this message translates to:
  /// **'Failed to repeat password'**
  String get failedToRepeatPasswordMessage;

  /// Message that appears after a failure of submitting a valid number
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumberMessage;

  /// Message that appears after a successful profile edit
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdateSuccessfulMessage;

  /// Message that appears after an unsuccessful profile edit
  ///
  /// In en, this message translates to:
  /// **'Profile failed to update'**
  String get profileUpdateFailedMessage;

  /// Message that appears after losing connection to the server
  ///
  /// In en, this message translates to:
  /// **'Lost connection to the server, check your internet connection'**
  String get noConnectionMessage;

  /// Message that appears when the location services are disabled when they're needed
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled, turn on your location'**
  String get noLocationServicesMessage;

  /// Message that appears when the location services permissions were denied when they're needed
  ///
  /// In en, this message translates to:
  /// **'Location services permissions were denied'**
  String get noLocationPermissionsMessage;

  /// Message that appears when the location services permissions are denied forever when they're needed
  ///
  /// In en, this message translates to:
  /// **'Location services permissions are permanently denied, check your app settings'**
  String get noLocationPermissionsForeverMessage;

  /// A generic error message used in most cases
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
