import 'package:flutter/material.dart';

class CardThemes {
  // LMU White theme
  static const whiteTheme = LMUCardTheme(
    cardColor: Color.fromARGB(255, 162, 162, 162),
    textColor: Colors.black,
    secondaryTextColor: Colors.black54,
    logoColor: Colors.black,
    hologramColor: Colors.white,
    borderColor: Color.fromARGB(255, 184, 184, 184),
    name: 'Holo',
  );

  // LMU Green theme
  static const greenTheme = LMUCardTheme(
    cardColor: Color.fromARGB(255, 10, 78, 0),
    textColor: Colors.white,
    secondaryTextColor: Colors.white70,
    logoColor: Colors.white,
    hologramColor: Color.fromARGB(206, 255, 255, 255),
    borderColor: Color.fromARGB(255, 10, 78, 0),
    name: 'Green',
  );

  // LMU Dark theme
  static const darkTheme = LMUCardTheme(
    cardColor: Color.fromARGB(255, 10, 10, 10),
    textColor: Colors.white,
    secondaryTextColor: Color.fromARGB(255, 208, 208, 208),
    logoColor: Colors.white,
    hologramColor: Colors.white,
    borderColor: Color.fromARGB(255, 10, 10, 10),
    name: 'Dark',
  );

  // LMU Blue theme
  static const blueTheme = LMUCardTheme(
    cardColor: Color.fromARGB(255, 0, 70, 128),
    textColor: Colors.white,
    secondaryTextColor: Color.fromARGB(255, 208, 208, 208),
    logoColor: Colors.white,
    hologramColor: Colors.white,
    borderColor: Color.fromARGB(255, 0, 70, 128),
    name: 'Blue',
  );

  // List of all available themes
  static const List<LMUCardTheme> allThemes = [
    whiteTheme,
    greenTheme,
    darkTheme,
    blueTheme,
  ];
}

class LMUCardTheme {
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color logoColor;
  final Color hologramColor;
  final Color borderColor;
  final String name;

  // Shadow configuration - keeping these constant across themes
  static const double ambientShadowOpacity = 0.4;
  static const double ambientShadowBlur = 30.0;
  static const double ambientShadowYOffset = 8.0;
  static const double primaryShadowOpacity = 0.30;
  static const double midShadowOpacity = 0.15;
  static const double distantShadowOpacity = 0.05;

  // Movement settings - keeping these constant across themes
  static const double gestureSensitivity = 0.5;
  static const double gyroSensitivity = 0.5;
  static const double gyroSmoothing = 0.85;
  static const double hologramCenterMovement = 0.3;
  static const double shadowOffsetMultiplier = 25.0;
  static const double shadowIntensityMultiplier = 2.5;

  const LMUCardTheme({
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.logoColor,
    required this.hologramColor,
    required this.borderColor,
    required this.name,
  });
}
