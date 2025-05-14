import 'package:flutter/material.dart';
import 'holographic_card.dart';

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
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white],
            ),
          ),
          child: const Center(
            child: HolographicCard(
              // User data
              name: 'Anton Rockenstein',
              email: 'Anton.Rockenstein@campus.lmu.de',
              validUntil: 'Gültig bis 30.09.2025',
              matrikelnr: '12842818',
              lrzKennung: 'roa1284',
              braille: '⠇⠍⠥', // LMU in braille
              // Card appearance
              cardColor: Color.fromARGB(255, 0, 0, 0),
              hologramColor: Color.fromARGB(
                255,
                255,
                255,
                255,
              ), // Material Grey 400
              width: 350,
              height: 220,
              borderRadius: 15,
              borderCardColor: Color.fromARGB(255, 255, 255, 255),
              borderWidth: 5.0,

              // Shadow properties
              ambientShadowOpacity: 0.4,
              ambientShadowBlur: 30,
              ambientShadowYOffset: 8,
              primaryShadowOpacity: 0.30,
              midShadowOpacity: 0.15,
              distantShadowOpacity: 0.05,

              // Movement settings
              gestureSensitivity: 0.3,
              gyroSensitivity: 0.3,
              gyroSmoothing: 0.85,
              hologramCenterMovement: 0.3,
              shadowOffsetMultiplier: 25,
              shadowIntensityMultiplier: 2.5,

              // Assets
              logoAsset: 'assets/holograms/legal_logo.svg',
              hologramAsset: 'assets/holograms/LMU-Sigel.svg',
              hologramAsset2: 'assets/holograms/LMUcard.svg',
              textureAsset: 'assets/grain/grain1.jpeg',
            ),
          ),
        ),
      ),
    );
  }
}
