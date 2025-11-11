// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'English';

  @override
  String get appTitle => 'App';

  @override
  String get loginPageTitle => 'Login';

  @override
  String get registerPageTitle => 'Register';

  @override
  String get trackPageTitle => 'Map';

  @override
  String get resultPageTitle => 'Results';

  @override
  String get usernameLabel => 'Username';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Repeat password';

  @override
  String get forgotPasswordLabel => 'Forgot password?';

  @override
  String get registerDuringLoginLabel => 'Don\'t have an account? Sign up';

  @override
  String get loginDuringRegisterLabel => 'Already have an account? Login';

  @override
  String get loginButtonLabel => 'Login';

  @override
  String get registerButtonLabel => 'Register';

  @override
  String get beginActivityButtonLabel => 'START ACTIVITY';

  @override
  String get stopActivityButtonLabel => 'STOP ACTIVITY';

  @override
  String get loginSuccessfulMessage => 'Login Successful';

  @override
  String get registerSuccessfulMessage => 'Registration successful';

  @override
  String get emptyFieldMessage => 'Fill out all required fields';

  @override
  String get badLoginMessage => 'Incorrect login credentials';

  @override
  String get emailTakenMessage => 'Email is already taken';

  @override
  String get incorrectEmailMessage => 'Incorrect email';

  @override
  String get incorrectPasswordMessage => 'Incorrect password';

  @override
  String get failedToRepeatPasswordMessage => 'Failed to repeat password';

  @override
  String get noConnectionMessage =>
      'Lost connection to the server, check your internet connection';

  @override
  String get noLocationServicesMessage =>
      'Location services are disabled, turn on your location';

  @override
  String get noLocationPermissionsMessage =>
      'Location services permissions were denied';

  @override
  String get noLocationPermissionsForeverMessage =>
      'Location services permissions are permanently denied, check your app settings';

  @override
  String get genericErrorMessage => 'An error has occurred, try again later';
}
