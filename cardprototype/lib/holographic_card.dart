import 'dart:math' as math;
import 'dart:async'; // For StreamSubscription
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart'; // For device motion
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';

class HolographicCard extends StatefulWidget {
  const HolographicCard({super.key});

  @override
  State<HolographicCard> createState() => _HolographicCardState();
}

class _HolographicCardState extends State<HolographicCard>
    with TickerProviderStateMixin {
  // Changed to TickerProviderStateMixin for multiple controllers
  // Mock data based on the image
  final String name = 'Anton Rockenstein';
  final String email = 'Anton.Rockenstein@campus.lmu.de';
  final String validUntil = 'Gültig bis 30.09.2025';
  final String matrikelnr = '12842818';
  final String lrzKennung = 'roa1284';

  Offset _offset =
      Offset.zero; // To store the pointer offset (now relative to center)
  // bool _isPointerDown = false; // No longer strictly needed for this logic version
  late AnimationController _returnToCenterController; // Renamed for clarity
  late Animation<Offset> _returnAnimation;

  // For device motion
  Offset _gyroscopeOffset = Offset.zero; // Stores tilt derived from gyroscope
  Offset _targetGyroscopeOffset =
      Offset.zero; // Target values for smooth interpolation
  StreamSubscription? _gyroscopeSubscription;
  late AnimationController _gyroSmoothingController;
  DateTime _lastGyroUpdate = DateTime.now();
  static const _minUpdateInterval = Duration(milliseconds: 16); // Cap at ~60fps

  // For flip animation
  late AnimationController _flipController;
  bool _isFlipped = false;

  // Sensitivity factors (can be tweaked)
  static const double _gestureSensitivity = 0.3;
  static const double _gyroSensitivity = 0.3;
  static const double _gyroSmoothing =
      0.85; // Higher = smoother but more latency

  ui.FragmentProgram? _holographicProgram;

  @override
  void initState() {
    super.initState();
    _returnToCenterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _returnToCenterController.addListener(() {
      setState(() {
        _offset = _returnAnimation.value;
      });
    });

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _gyroSmoothingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..addListener(_updateGyroscope);

    _gyroscopeSubscription = gyroscopeEvents.listen(_handleGyroscopeEvent);

    _loadHolographicShader();
  }

  void _handleGyroscopeEvent(GyroscopeEvent event) {
    final now = DateTime.now();
    if (now.difference(_lastGyroUpdate) < _minUpdateInterval) {
      return; // Skip update if too soon
    }
    _lastGyroUpdate = now;

    // Update target values
    _targetGyroscopeOffset = Offset(
      _targetGyroscopeOffset.dx * _gyroSmoothing +
          (event.y * _gyroSensitivity) * (1 - _gyroSmoothing),
      _targetGyroscopeOffset.dy * _gyroSmoothing +
          (-event.x * _gyroSensitivity) * (1 - _gyroSmoothing),
    );

    // Ensure animation is running
    if (!_gyroSmoothingController.isAnimating) {
      _gyroSmoothingController.repeat();
    }
  }

  void _updateGyroscope() {
    if (!mounted) return;

    setState(() {
      _gyroscopeOffset = Offset(
        _gyroscopeOffset.dx +
            (_targetGyroscopeOffset.dx - _gyroscopeOffset.dx) * 0.1,
        _gyroscopeOffset.dy +
            (_targetGyroscopeOffset.dy - _gyroscopeOffset.dy) * 0.1,
      );
    });
  }

  Future<void> _loadHolographicShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/holographic_shader.frag.glsl',
      );
      if (mounted) {
        setState(() {
          _holographicProgram = program;
        });
      }
    } catch (error) {
      print('Error loading shader: $error');
      if (mounted) {
        setState(() {
          _holographicProgram = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _returnToCenterController.dispose();
    _flipController.dispose();
    _gyroSmoothingController.dispose();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parallax rotations from gestures (offset is now -0.5 to 0.5)
    final double gestureRotateX = -_offset.dy * _gestureSensitivity;
    final double gestureRotateY = _offset.dx * _gestureSensitivity;

    // Parallax rotations from gyroscope
    final double gyroRotateX =
        -_gyroscopeOffset.dy; // dy influences X-axis rotation
    final double gyroRotateY =
        _gyroscopeOffset.dx; // dx influences Y-axis rotation

    // Combined rotation
    final double finalRotateX = gestureRotateX + gyroRotateX;
    final double finalRotateY = gestureRotateY + gyroRotateY;

    return GestureDetector(
      onPanStart: (details) {
        // setState(() { _isPointerDown = true; }); // Not strictly needed
        _returnToCenterController.stop();
      },
      onPanUpdate: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        setState(() {
          _offset = Offset(
            (localPosition.dx / renderBox.size.width) - 0.5, // Center is (0,0)
            (localPosition.dy / renderBox.size.height) - 0.5, // Center is (0,0)
          );
        });
      },
      onPanEnd: (details) {
        // setState(() { _isPointerDown = false; }); // Not strictly needed
        _returnAnimation = Tween<Offset>(
          begin: _offset,
          end: Offset.zero, // Animate back to center
        ).animate(
          CurvedAnimation(
            parent: _returnToCenterController,
            curve: Curves.easeOut,
          ),
        );
        _returnToCenterController.forward(from: 0);
      },
      onDoubleTap: () {
        if (_isFlipped) {
          _flipController.reverse();
        } else {
          _flipController.forward();
        }
        _isFlipped = !_isFlipped;
      },
      child: AnimatedBuilder(
        // Use AnimatedBuilder for flip animation
        animation: _flipController,
        builder: (context, child) {
          final double flipValue = _flipController.value;
          final Matrix4 flipTransform =
              Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective for flip
                ..rotateY(math.pi * flipValue); // Rotate around Y-axis

          return Transform(
            transform:
                Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective for parallax
                  ..rotateX(finalRotateX)
                  ..rotateY(finalRotateY),
            alignment: FractionalOffset.center,
            child: Transform(
              // Apply flip transform
              transform: flipTransform,
              alignment: FractionalOffset.center,
              child: child,
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              if (_holographicProgram == null) {
                return ui.Gradient.linear(
                  Offset.zero,
                  Offset(bounds.width, bounds.height),
                  [Colors.transparent, Colors.transparent],
                );
              }

              final shader = _holographicProgram!.fragmentShader();

              // Combine touch and gyroscope effects
              final combinedX = _offset.dx + _gyroscopeOffset.dx;
              final combinedY = _offset.dy + _gyroscopeOffset.dy;

              // Calculate center position based on movement
              // Invert the movement for more natural feel (tilt right = effect moves left)
              final centerX =
                  0.5 + // Center point
                  (-combinedX * 0.3).clamp(-0.3, 0.3); // Move ±0.3 from center

              final centerY =
                  0.5 + // Center point
                  (-combinedY * 0.3).clamp(-0.3, 0.3); // Move ±0.3 from center

              shader.setFloat(0, bounds.width);
              shader.setFloat(1, bounds.height);
              // Use combined movement for shader pointer position
              shader.setFloat(2, (combinedX + 0.5).clamp(0.0, 1.0));
              shader.setFloat(3, (combinedY + 0.5).clamp(0.0, 1.0));
              shader.setFloat(4, centerX);
              shader.setFloat(5, centerY);

              return shader;
            },
            blendMode: BlendMode.srcOver,
            child: Builder(
              builder: (context) {
                // Calculate combined movement here so it's available for both shader and shadow
                final combinedX = _offset.dx + _gyroscopeOffset.dx;
                final combinedY = _offset.dy + _gyroscopeOffset.dy;

                return Container(
                  width: 350,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      // Main shadow that moves with tilt
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(
                          -combinedX * 20, // Shadow moves opposite to tilt
                          -combinedY * 20 + 5, // Add base Y offset of 5
                        ),
                        spreadRadius: 2,
                      ),
                      // Ambient shadow that stays constant
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Conditionally show front or back
                      if (_flipController.value < 0.5) ...[
                        // LMU Logo (top-left) - Placeholder
                        Positioned(
                          top: 20,
                          left: 20,
                          child: SvgPicture.asset(
                            'assets/holograms/legal_logo.svg',
                            width: 45,
                            height: 45,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcATop,
                            ),
                          ),
                        ),

                        // Name
                        Positioned(
                          top: 70,
                          left: 20,
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Email
                        Positioned(
                          top: 95,
                          left: 20,
                          child: Text(
                            email,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        // Valid until
                        Positioned(
                          top: 115,
                          left: 20,
                          child: Text(
                            validUntil,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        // Matrikelnr
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Matrikelnr',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    matrikelnr,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.copy,
                                    color: Colors.black54,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // LRZ Kennung
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'LRZ Kennung',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    lrzKennung,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.copy,
                                    color: Colors.black54,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Placeholder for Braille dots
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Text(
                            '● ●●\n●● ●',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 10,
                              letterSpacing: 2,
                              height: 0.8,
                            ),
                          ),
                        ),

                        // LMU Sigel with holographic effect
                        Positioned(
                          bottom: -30,
                          right: 10,
                          child: Opacity(
                            opacity: 1,
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green[400]!.withOpacity(0),
                                    Colors.green[400]!.withOpacity(1),
                                    Colors.green[400]!.withOpacity(0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: SvgPicture.asset(
                                'assets/holograms/LMU-Sigel.svg',
                                width: 200,
                                height: 200,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white70,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Back of the card
                        Center(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: const Text(
                              'Card Back',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
