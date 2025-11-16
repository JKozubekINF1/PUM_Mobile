import 'package:flutter/material.dart';
import 'package:pum_project/pages/firstvisit.dart';
import 'package:pum_project/pages/home.dart';
import 'package:pum_project/pages/login.dart';
import 'package:pum_project/pages/register.dart';
import 'package:pum_project/pages/resetpassword.dart';
import 'package:pum_project/pages/track.dart';
import 'package:pum_project/pages/activityresult.dart';
import 'package:pum_project/pages/profile.dart';
import 'package:pum_project/pages/editprofile.dart';
import 'package:pum_project/pages/settings.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:pum_project/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
      MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            Provider<ApiService>(create: (context) => ApiService()),
          ],
      child: const MyApp(),
      ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  static String? getLocale(BuildContext context) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    return state?.getLocale();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  String getLocale() {
    if (_locale==null) {
      return 'en';
    }
    return _locale.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        return "App";
      },
      routes: {
        '/' : (BuildContext context)=>const FirstVisitPage(),
        '/home' : (BuildContext context)=>const HomePage(),
        '/login' : (BuildContext context)=>const LoginPage(),
        '/register' : (BuildContext context)=>const RegisterPage(),
        '/resetpassword' : (BuildContext context)=>const ResetPage(),
        '/track' : (BuildContext context)=>const TrackPage(),
        '/profile' : (BuildContext context)=>const ProfilePage(),
        '/profile/edit' : (BuildContext context)=>const EditProfilePage(),
        '/settings' : (BuildContext context)=>const SettingsPage(),
        '/results' : (BuildContext context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ResultScreen(
            duration: args['Duration'],
            route: args['RouteList'],
            distance: args['Distance'],
            speedavg: args['SpeedAvg'],
          );
        },
      },
      theme: AppTheme.lightTheme,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}