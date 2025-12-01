import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 24),
        bodyLarge: TextStyle(fontSize: 72),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.grey,
          textStyle: TextStyle(fontSize: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: TextStyle(fontSize: 24),
        labelStyle: TextStyle(fontSize: 24),
      ),
      datePickerTheme: DatePickerThemeData(
        headerHelpStyle: TextStyle(fontSize: 18),
        headerHeadlineStyle: TextStyle(fontSize: 18),
        dayStyle: TextStyle(fontSize: 18),
        weekdayStyle: TextStyle(fontSize: 18),
        yearStyle: TextStyle(fontSize: 18),
        inputDecorationTheme: InputDecorationThemeData(
          floatingLabelStyle: TextStyle(fontSize: 24),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(fontSize: 18),
      ),
    );
  }

  static ThemeData get testTheme {
    return ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: Colors.red,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 24),
        bodyLarge: TextStyle(fontSize: 72),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.grey,
          textStyle: TextStyle(fontSize: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: TextStyle(fontSize: 24),
        labelStyle: TextStyle(fontSize: 24),
      ),
      datePickerTheme: DatePickerThemeData(
        headerHelpStyle: TextStyle(fontSize: 18),
        headerHeadlineStyle: TextStyle(fontSize: 18),
        dayStyle: TextStyle(fontSize: 18),
        weekdayStyle: TextStyle(fontSize: 18),
        yearStyle: TextStyle(fontSize: 18),
        inputDecorationTheme: InputDecorationThemeData(
          floatingLabelStyle: TextStyle(fontSize: 24),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(fontSize: 18),
      ),
    );
  }
}