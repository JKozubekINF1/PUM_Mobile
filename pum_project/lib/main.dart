import 'package:flutter/material.dart';
import 'package:pum_project/pages/login.dart';
import 'package:pum_project/pages/register.dart';
import 'package:pum_project/pages/resetpassword.dart';
import 'package:pum_project/pages/track.dart';
import 'package:pum_project/pages/activityresult.dart';
import 'package:pum_project/pages/home_page.dart';
import 'package:pum_project/pages/profile_page.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        Provider<ApiService>(create: (_) => ApiService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        return "App";
      },
      routes: {
        '/' : (BuildContext context)=>const HomePage(),
        '/login' : (BuildContext context)=>const LoginPage(),
        '/register' : (BuildContext context)=>const RegisterPage(),
        '/resetpassword' : (BuildContext context)=>const ResetPage(),
        '/track' : (BuildContext context)=>const TrackPage(),
        '/profile' : (BuildContext context)=>const ProfilePage(),
        '/results' : (BuildContext context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ResultScreen(
            duration: args['Duration'],
            route: args['RouteList'],
            distance: args['Distance'],
            speed: args['Speed'],
            speedavg: args['SpeedAvg'],
          );
        },
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}