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
  String get loginSuccessfulMessage => 'Login Successful';

  @override
  String get registerSuccessfulMessage => 'Registration successful';

  @override
  String get emptyFieldMessage => 'Fill out all required fields';

  @override
  String get badLoginMessage => 'Incorrect login credentials';

  @override
  String get noConnectionMessage =>
      'Lost connection to the server, check your internet connection';

  @override
  String get genericErrorMessage => 'An error has occurred, try again later';
}
