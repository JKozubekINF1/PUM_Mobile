import 'package:flutter/material.dart';

class AppTheme {
  static const EdgeInsets _defaultInputPadding = EdgeInsets.symmetric(
    vertical: 14.0,
    horizontal: 16.0,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color appBarBg,
    required Color appBarFg,
    required Color textColor,
    required Color iconColor,
    required Color cardColor,
    required Color buttonBg,
    required Color buttonFg,
    required Color borderColor,
  }) {
    return ThemeData(
      useMaterial3: false,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,

      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        centerTitle: true,
        elevation: 0,
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 24),
        bodyLarge: TextStyle(fontSize: 72),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ).apply(bodyColor: textColor, displayColor: textColor),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: buttonFg,
          backgroundColor: buttonBg,
          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),

      iconTheme: IconThemeData(color: iconColor),
      textSelectionTheme: TextSelectionThemeData(cursorColor: iconColor),

      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
        ),
      ),


      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        contentPadding: _defaultInputPadding,
        filled: true,
        fillColor: cardColor.withOpacity(0.5),
        floatingLabelBehavior: FloatingLabelBehavior.always,

        labelStyle: TextStyle(fontSize: 24, color: textColor),
        hintStyle: TextStyle(fontSize: 24, color: textColor.withOpacity(0.7)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 56),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(fontSize: 20),
        menuStyle: MenuStyle(backgroundColor: WidgetStateProperty.all(cardColor)),
      ),

      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: Colors.blueGrey,
      ),
    );
  }


  static ThemeData get defaultTheme => _buildTheme(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    scaffoldBg: Colors.white,
    appBarBg: Colors.blue,
    appBarFg: Colors.white,
    textColor: Colors.black,
    iconColor: Colors.blue[900]!,
    cardColor: Colors.blueGrey[200]!,
    buttonBg: Colors.blueGrey[400]!,
    buttonFg: Colors.black,
    borderColor: Colors.blue[900]!,
  );

  static ThemeData get darkTheme => _buildTheme(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
    scaffoldBg: Colors.grey[900]!,
    appBarBg: Colors.black,
    appBarFg: Colors.white,
    textColor: Colors.white,
    iconColor: Colors.white,
    cardColor: Colors.grey[800]!,
    buttonBg: Colors.grey[700]!,
    buttonFg: Colors.white,
    borderColor: Colors.white,
  );

  static ThemeData get christmasTheme => _buildTheme(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
    scaffoldBg: const Color(0xFF8B0000),       
    appBarBg: const Color(0xFF1B5E20),
    appBarFg: const Color(0xFFFFD700),
    textColor: const Color(0xFFFFE082),
    iconColor: const Color(0xFFFFE082),
    cardColor: const Color(0xFF2E7D32),
    buttonBg: const Color(0xFFFFFFFF),
    buttonFg: const Color(0xFF8B0000),
    borderColor: const Color(0xFFFFD700),
  );

  static ThemeData get halloweenTheme => _buildTheme(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
    scaffoldBg: const Color(0xFF353535),
    appBarBg: const Color(0xFFFF7216),
    appBarFg: const Color(0xFF000000),
    textColor: const Color(0xFFC99BCD),
    iconColor: const Color(0xFF973613),
    cardColor: const Color(0xFF1C1C1C),
    buttonBg: const Color(0xFF60147E),
    buttonFg: const Color(0xFFC99BCD),
    borderColor: const Color(0xFFC99BCD),
  );
}