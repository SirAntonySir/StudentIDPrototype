import 'package:flutter/material.dart';
import 'holographic_card.dart';
import 'themes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMU Student Card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: CardThemes.greenTheme.cardColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const StudentCardScreen(),
    );
  }
}

class StudentCardScreen extends StatefulWidget {
  const StudentCardScreen({super.key});

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  LMUCardTheme currentTheme = CardThemes.whiteTheme;

  void _changeTheme(LMUCardTheme newTheme) {
    setState(() {
      currentTheme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('LMU Student ID Card'),
        backgroundColor: currentTheme.cardColor,
        foregroundColor: currentTheme.textColor,
        actions: [
          PopupMenuButton<LMUCardTheme>(
            icon: Icon(Icons.palette, color: currentTheme.textColor),
            onSelected: _changeTheme,
            itemBuilder: (BuildContext context) {
              return CardThemes.allThemes.map((LMUCardTheme theme) {
                return PopupMenuItem<LMUCardTheme>(
                  value: theme,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(theme.name),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StudentIDCard(theme: currentTheme),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentIDCard extends StatelessWidget {
  final LMUCardTheme theme;

  const StudentIDCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return HolographicCard(
      // User data
      name: 'Anton Rockenstein',
      email: 'Anton.Rockenstein@campus.lmu.de',
      validUntil: 'Gültig bis 30.09.2025',
      matrikelnr: '12842818',
      lrzKennung: 'roa1284',
      braille: '⠇⠍⠥',

      // Card appearance
      cardColor: theme.cardColor,
      textColor: theme.textColor,
      secondaryTextColor: theme.secondaryTextColor,
      logoColor: theme.logoColor,
      hologramColor: theme.hologramColor,
      width: 350,
      height: 220,
      borderRadius: 15,
      borderCardColor: theme.borderColor,
      borderWidth: 2.0,

      // Shadow properties
      ambientShadowOpacity: LMUCardTheme.ambientShadowOpacity,
      ambientShadowBlur: LMUCardTheme.ambientShadowBlur,
      ambientShadowYOffset: LMUCardTheme.ambientShadowYOffset,
      primaryShadowOpacity: LMUCardTheme.primaryShadowOpacity,
      midShadowOpacity: LMUCardTheme.midShadowOpacity,
      distantShadowOpacity: LMUCardTheme.distantShadowOpacity,

      // Movement settings
      gestureSensitivity: LMUCardTheme.gestureSensitivity,
      gyroSensitivity: LMUCardTheme.gyroSensitivity,
      gyroSmoothing: LMUCardTheme.gyroSmoothing,
      hologramCenterMovement: LMUCardTheme.hologramCenterMovement,
      shadowOffsetMultiplier: LMUCardTheme.shadowOffsetMultiplier,
      shadowIntensityMultiplier: LMUCardTheme.shadowIntensityMultiplier,

      // Assets
      logoAsset: 'assets/holograms/legal_logo.svg',
      hologramAsset: 'assets/holograms/LMU-Sigel.svg',
      hologramAsset2: 'assets/holograms/LMUcard.svg',
      textureAsset: 'assets/grain/grain1.jpeg',
    );
  }
}
