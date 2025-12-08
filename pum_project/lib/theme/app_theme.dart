import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get defaultTheme {
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
      ).apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.blueGrey[400],
          textStyle: TextStyle(fontSize: 24),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.blueGrey[200],
      ),
      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: TextStyle(
          fontSize: 24,
          color: Colors.black,
        ),
        labelStyle: TextStyle(
          fontSize: 24,
          color: Colors.black,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[900]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[900]!),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: Colors.blueGrey,
        headerHelpStyle: TextStyle(fontSize: 18),
        headerHeadlineStyle: TextStyle(fontSize: 18),
        dayStyle: TextStyle(fontSize: 18),
        weekdayStyle: TextStyle(fontSize: 18,color: Colors.black),
        yearStyle: TextStyle(fontSize: 18,color:Colors.black),
        inputDecorationTheme: InputDecorationThemeData(
          floatingLabelStyle: TextStyle(fontSize: 24),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          fontSize: 18,
        ),
      ),
      iconTheme: IconThemeData(
        color: Colors.blue[900],
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          iconColor: Colors.blue[900],
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.black,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 24),
        bodyLarge: TextStyle(fontSize: 72),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.grey[700],
          textStyle: TextStyle(fontSize: 24),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[800],
      ),
      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: TextStyle(
            fontSize: 24,
            color: Colors.white,
        ),
        labelStyle: TextStyle(
            fontSize: 24,
            color: Colors.white,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: Colors.blueGrey,
        headerHelpStyle: TextStyle(fontSize: 18),
        headerHeadlineStyle: TextStyle(fontSize: 18),
        dayStyle: TextStyle(fontSize: 18),
        weekdayStyle: TextStyle(fontSize: 18,color: Colors.black),
        yearStyle: TextStyle(fontSize: 18,color:Colors.black),
        inputDecorationTheme: InputDecorationThemeData(
          floatingLabelStyle: TextStyle(fontSize: 24),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          fontSize: 18,
        ),
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          iconColor: Colors.white,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.white,
      ),
    );
  }

  static ThemeData get christmasTheme {
    return ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      scaffoldBackgroundColor: Colors.red[600],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0E8919),
        foregroundColor: Color(0xFFFBEE76),
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 24),
        bodyLarge: TextStyle(fontSize: 72),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ).apply(
        bodyColor: Color(0xFFFBEE76),
        displayColor: Color(0xFFFBEE76),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Color(0xFFFBEE76),
          backgroundColor: Color(0xFFFF1F1F),
          textStyle: TextStyle(fontSize: 24),
        ),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF05D30C),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: TextStyle(
          fontSize: 24,
          color: Color(0xFFFBEE76),
        ),
        labelStyle: TextStyle(
          fontSize: 24,
          color: Color(0xFFFBEE76),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFFBEE76)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFFBEE76)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: Colors.blueGrey,
        headerHelpStyle: TextStyle(fontSize: 18),
        headerHeadlineStyle: TextStyle(fontSize: 18),
        dayStyle: TextStyle(fontSize: 18),
        weekdayStyle: TextStyle(fontSize: 18,color: Colors.black),
        yearStyle: TextStyle(fontSize: 18,color:Colors.black),
        inputDecorationTheme: InputDecorationThemeData(
          floatingLabelStyle: TextStyle(fontSize: 24),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          fontSize: 18,
        ),
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFFBEE76),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          iconColor: Color(0xFFFBEE76),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Color(0xFFFBEE76),
      ),
    );
  }

  static ThemeData get halloweenTheme {
    return ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      scaffoldBackgroundColor: Color(0xFF353535),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFF7216),
        foregroundColor: Color(0xFF000000),
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 24),
        bodyLarge: TextStyle(fontSize: 72),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ).apply(
        bodyColor: Color(0xFFC99BCD),
        displayColor: Color(0xFFC99BCD),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Color(0xFFC99BCD),
          backgroundColor: Color(0xFF60147E),
          textStyle: TextStyle(fontSize: 24),
        ),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF1C1C1C),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: TextStyle(
          fontSize: 24,
          color: Color(0xFFC99BCD),
        ),
        labelStyle: TextStyle(
          fontSize: 24,
          color: Color(0xFFC99BCD),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFC99BCD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFC99BCD)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: Colors.blueGrey,
        headerHelpStyle: TextStyle(fontSize: 18),
        headerHeadlineStyle: TextStyle(fontSize: 18),
        dayStyle: TextStyle(fontSize: 18),
        weekdayStyle: TextStyle(fontSize: 18,color: Colors.black),
        yearStyle: TextStyle(fontSize: 18,color:Colors.black),
        inputDecorationTheme: InputDecorationThemeData(
          floatingLabelStyle: TextStyle(fontSize: 24),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          fontSize: 18,
        ),
      ),
      iconTheme: IconThemeData(
        color: Color(0xFF973613),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          iconColor: Color(0xFF973613),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Color(0xFF973613),
      ),
    );
  }
}