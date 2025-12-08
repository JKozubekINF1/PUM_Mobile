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
import 'package:pum_project/pages/viewonlineactivity.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:pum_project/services/app_settings.dart';
import 'package:pum_project/services/local_storage.dart';
import 'package:pum_project/services/upload_queue.dart';
import 'package:pum_project/services/route_observer.dart';
import 'package:pum_project/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocalStorage.init();
  // NEEDED FOR WINDOWS TESTING
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // COMMENT WHEN TESTING ON ANDROID
  await UploadQueue.instance.init();
  runApp(
      MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            Provider<ApiService>(create: (context) => ApiService()),
            Provider<AppSettings>(create: (context) => AppSettings()),
            Provider<LocalStorage>(create: (context) => LocalStorage()),
            Provider<UploadQueue>(create: (context) => UploadQueue.instance),
          ],
        child: Builder(
          builder: (context) {
            return const MyApp();
          },
        ),
      ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  static void setTheme(BuildContext context, String newThemeName) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setTheme(newThemeName);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  ThemeData? _theme = AppTheme.defaultTheme;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void setTheme(String themeName) {
    setState(() {
      switch(themeName) {
        case "default": _theme = AppTheme.defaultTheme; break;
        case "dark": _theme = AppTheme.darkTheme; break;
        case "christmas": _theme = AppTheme.christmasTheme; break;
        case "halloween": _theme = AppTheme.halloweenTheme; break;
      }
    });
  }

  Future<void> loadSettings() async{
    try {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final settings = await appSettings.getSettings();
      if (mounted) {
        setState(() {
          _locale = Locale(settings?["language"] ?? "en");
        });
        setTheme(settings?["theme"] ?? "default");
      }
    } catch (e) {
      debugPrint('Failed to fetch settings');
    }
  }

  @override
  void initState() {
    loadSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        return "App";
      },
      navigatorObservers: [routeObserver],
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
            data: args['Data'],
          );
        },
        '/activity/get' : (BuildContext context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ViewOnlineActivityScreen(
            data: args['Data'],
          );
        },
      },
      theme: _theme,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}