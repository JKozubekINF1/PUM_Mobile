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
  String get firstVisitPageTitle => 'Welcome';

  @override
  String get loginPageTitle => 'Login';

  @override
  String get registerPageTitle => 'Register';

  @override
  String get homePageTitle => 'Homepage';

  @override
  String get trackPageTitle => 'Map';

  @override
  String get resultPageTitle => 'Results';

  @override
  String get profilePageTitle => 'Your Profile';

  @override
  String get warningLabel => 'Warning';

  @override
  String get acceptOptionLabel => 'Agree';

  @override
  String get declineOptionLabel => 'Decline';

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
  String get logoutButtonLabel => 'Logout';

  @override
  String get profileButtonLabel => 'Profile';

  @override
  String get offlineModeTextLabel => 'or open in offline mode';

  @override
  String get profileFirstNameLabel => 'First Name';

  @override
  String get profileLastNameLabel => 'Last Name';

  @override
  String get profileGenderLabel => 'Gender';

  @override
  String get profileDayOfBirthLabel => 'Date of birth';

  @override
  String get optionalLabel => 'Optional';

  @override
  String get profileGenderMaleLabel => 'Male';

  @override
  String get profileGenderFemaleLabel => 'Female';

  @override
  String get profileGenderOtherLabel => 'Other';

  @override
  String get profileHeightLabel => 'Height';

  @override
  String get profileWeightLabel => 'Weight';

  @override
  String get profileAvatarLabel => 'Profile Picture';

  @override
  String get saveChangesLabel => 'Save Changes';

  @override
  String get beginActivityButtonLabel => 'START ACTIVITY';

  @override
  String get stopActivityButtonLabel => 'STOP ACTIVITY';

  @override
  String get welcomeNewUserMessage => 'Log in or create a new account';

  @override
  String get offlineModeWarningMessage =>
      'Some app features are unavailable in offline mode. Are you sure you want to proceed?';

  @override
  String get loginSuccessfulMessage => 'Login Successful';

  @override
  String get registerSuccessfulMessage => 'Registration successful';

  @override
  String get logoutSuccessfulMessage => 'You have been logged out';

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
  String get enterValidNumberMessage => 'Enter a valid number';

  @override
  String get profileUpdateSuccessfulMessage => 'Profile updated successfully';

  @override
  String get profileUpdateFailedMessage => 'Profile failed to update';

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
