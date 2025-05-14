import 'dart:math' as math;
import 'dart:async'; // For StreamSubscription
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart'; // For device motion
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';

class HolographicCard extends StatefulWidget {
  // User data
  final String name;
  final String email;
  final String validUntil;
  final String matrikelnr;
  final String lrzKennung;
  final String braille;

  // Card dimensions
  final double width;
  final double height;
  final double borderRadius;
  final double borderWidth;
  // Card colors
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color logoColor;
  final Color hologramColor;
  final Color borderCardColor;
  // Shadow properties
  final double ambientShadowOpacity;
  final double ambientShadowBlur;
  final double ambientShadowYOffset;
  final double primaryShadowOpacity;
  final double midShadowOpacity;
  final double distantShadowOpacity;

  // Movement sensitivity
  final double gestureSensitivity;
  final double gyroSensitivity;
  final double gyroSmoothing;
  final double hologramCenterMovement;
  final double shadowOffsetMultiplier;
  final double shadowIntensityMultiplier;

  // Assets
  final String? logoAsset;
  final String? hologramAsset;
  final String? hologramAsset2;
  final String? textureAsset;

  const HolographicCard({
    super.key,
    // User data
    this.name = 'Anton Rockenstein',
    this.email = 'Anton.Rockenstein@campus.lmu.de',
    this.validUntil = 'Gültig bis 30.09.2025',
    this.matrikelnr = '12842818',
    this.lrzKennung = 'roa1284',
    this.braille = '⠇⠍⠥',

    // Card dimensions
    this.width = 350,
    this.height = 220,
    this.borderRadius = 15,
    this.borderWidth = 2.0,

    // Card colors
    this.cardColor = const Color(0xFFBEBEBE), // Light gray
    this.textColor = Colors.black,
    this.secondaryTextColor = Colors.black54,
    this.logoColor = Colors.black,
    this.hologramColor = Colors.white70,
    this.borderCardColor = Colors.black,

    // Shadow properties
    this.ambientShadowOpacity = 0.4,
    this.ambientShadowBlur = 30,
    this.ambientShadowYOffset = 8,
    this.primaryShadowOpacity = 0.30,
    this.midShadowOpacity = 0.15,
    this.distantShadowOpacity = 0.05,

    // Movement sensitivity
    this.gestureSensitivity = 0.3,
    this.gyroSensitivity = 0.3,
    this.gyroSmoothing = 0.85,
    this.hologramCenterMovement = 0.3,
    this.shadowOffsetMultiplier = 25,
    this.shadowIntensityMultiplier = 2.5,

    // Assets
    this.logoAsset,
    this.hologramAsset = 'assets/holograms/LMU-Sigel.svg',
    this.hologramAsset2 = 'assets/holograms/LMUcard.svg',
    this.textureAsset = 'assets/grain/grain1.jpeg',
  });

  @override
  State<HolographicCard> createState() => _HolographicCardState();
}

class _HolographicCardState extends State<HolographicCard>
    with TickerProviderStateMixin {
  Offset _offset = Offset.zero; // To store the pointer offset
  late AnimationController _returnToCenterController;
  late Animation<Offset> _returnAnimation;

  // For device motion
  Offset _gyroscopeOffset = Offset.zero;
  Offset _targetGyroscopeOffset = Offset.zero;
  StreamSubscription? _gyroscopeSubscription;
  late AnimationController _gyroSmoothingController;
  DateTime _lastGyroUpdate = DateTime.now();
  static const _minUpdateInterval = Duration(milliseconds: 16); // Cap at ~60fps

  // For flip animation
  late AnimationController _flipController;
  bool _isFlipped = false;

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
      _targetGyroscopeOffset.dx * widget.gyroSmoothing +
          (event.y * widget.gyroSensitivity) * (1 - widget.gyroSmoothing),
      _targetGyroscopeOffset.dy * widget.gyroSmoothing +
          (-event.x * widget.gyroSensitivity) * (1 - widget.gyroSmoothing),
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
    final double gestureRotateX = -_offset.dy * widget.gestureSensitivity;
    final double gestureRotateY = _offset.dx * widget.gestureSensitivity;

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
              child: Builder(
                builder: (context) {
                  // Calculate combined movement here so it's available for shadow
                  final combinedX = _offset.dx + _gyroscopeOffset.dx;
                  final combinedY = _offset.dy + _gyroscopeOffset.dy;

                  // Calculate shadow values based on tilt
                  final shadowIntensity =
                      math.sqrt(combinedX * combinedX + combinedY * combinedY) *
                      widget.shadowIntensityMultiplier;
                  final shadowIntensityLimited = shadowIntensity.clamp(
                    0.0,
                    1.0,
                  );

                  // Shadow direction based on tilt
                  final shadowOffsetX =
                      -combinedX * widget.shadowOffsetMultiplier;
                  final shadowOffsetY =
                      -combinedY * widget.shadowOffsetMultiplier;

                  // Shadow size increases with intensity
                  final shadowSpreadBase = 0.2;
                  final shadowSpread =
                      shadowSpreadBase + shadowIntensityLimited * 2.0;

                  // Shadow blur increases with distance from card
                  final shadowBlurBase = 6.0;
                  final shadowBlur =
                      shadowBlurBase + shadowIntensityLimited * 25.0;

                  return Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      boxShadow: [
                        // Ambient soft shadow that's always visible for resting state
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            widget.ambientShadowOpacity,
                          ),
                          blurRadius: widget.ambientShadowBlur,
                          offset: Offset(0, widget.ambientShadowYOffset),
                          spreadRadius: 0,
                        ),
                        // Primary shadow - closest to card, follows movement most
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            widget.primaryShadowOpacity *
                                shadowIntensityLimited,
                          ),
                          blurRadius: shadowBlur * 0.3,
                          offset: Offset(
                            shadowOffsetX * 0.8,
                            shadowOffsetY * 0.8 + 2,
                          ),
                          spreadRadius: shadowSpread * 0.3,
                        ),
                        // Mid-level shadow - larger spread, more diffuse
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            widget.midShadowOpacity * shadowIntensityLimited,
                          ),
                          blurRadius: shadowBlur * 0.8,
                          offset: Offset(
                            shadowOffsetX * 0.9,
                            shadowOffsetY * 0.9 + 6,
                          ),
                          spreadRadius: shadowSpread * 0.8,
                        ),
                        // Distant shadow - largest, most diffuse
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            widget.distantShadowOpacity *
                                shadowIntensityLimited,
                          ),
                          blurRadius: shadowBlur * 1.5,
                          offset: Offset(shadowOffsetX, shadowOffsetY + 10),
                          spreadRadius: shadowSpread * 1.5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
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
                              (-combinedX * widget.hologramCenterMovement)
                                  .clamp(-0.3, 0.3); // Move ±0.3 from center

                          final centerY =
                              0.5 + // Center point
                              (-combinedY * widget.hologramCenterMovement)
                                  .clamp(-0.3, 0.3); // Move ±0.3 from center

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
                        child: Container(
                          width: widget.width,
                          height: widget.height,
                          decoration: BoxDecoration(
                            color: widget.cardColor,
                            borderRadius: BorderRadius.circular(
                              widget.borderRadius,
                            ),
                            border: Border.all(
                              color: widget.borderCardColor,
                              width: widget.borderWidth,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Conditionally show front or back
                              if (_flipController.value < 0.5) ...[
                                // LMU Logo (top-left)
                                Positioned(
                                  top: 20,
                                  left: 20,
                                  child:
                                      widget.logoAsset != null
                                          ? SvgPicture.asset(
                                            widget.logoAsset!,
                                            width: 62,
                                            height: 32,
                                            colorFilter: ColorFilter.mode(
                                              widget.logoColor,
                                              BlendMode.srcIn,
                                            ),
                                          )
                                          : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                color: Colors.black,
                                                child: Text(
                                                  'LMU',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'LUDWIG-\nMAXIMILIANS-\nUNIVERSITÄT\nMÜNCHEN',
                                                style: TextStyle(
                                                  color: widget.textColor,
                                                  fontSize:
                                                      5, // Very small text
                                                  height: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),

                                // Name
                                Positioned(
                                  top: 70,
                                  left: 20,
                                  child: Text(
                                    widget.name,
                                    style: TextStyle(
                                      color: widget.textColor,
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
                                    widget.email,
                                    style: TextStyle(
                                      color: widget.secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                                // Valid until
                                Positioned(
                                  top: 115,
                                  left: 20,
                                  child: Text(
                                    widget.validUntil,
                                    style: TextStyle(
                                      color: widget.textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                                // Matrikelnr
                                Positioned(
                                  bottom: 20,
                                  left: 20,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Matrikelnr',
                                        style: TextStyle(
                                          color: widget.secondaryTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            widget.matrikelnr,
                                            style: TextStyle(
                                              color: widget.textColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Icon(
                                            Icons.copy,
                                            color: widget.secondaryTextColor,
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
                                      Text(
                                        'LRZ Kennung',
                                        style: TextStyle(
                                          color: widget.secondaryTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            widget.lrzKennung,
                                            style: TextStyle(
                                              color: widget.textColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Icon(
                                            Icons.copy,
                                            color: widget.secondaryTextColor,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Braille
                                Positioned(
                                  top: 30,
                                  right: 30, // Changed from right to left
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform:
                                        Matrix4.identity()..scale(
                                          -1.0,
                                          1.0,
                                        ), // Horizontal mirror
                                    child: Text(
                                      widget.braille,
                                      style: TextStyle(
                                        color: widget.textColor.withOpacity(
                                          0.3,
                                        ),
                                        fontSize: 24,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),

                                // Hologram with effect (1st hologram - visible at certain angles)
                                if (widget.hologramAsset != null)
                                  Positioned(
                                    bottom: -30,
                                    right: 0,
                                    child: Opacity(
                                      // Fade in/out based on Y-axis tilt
                                      opacity: (0.8 - combinedY.abs() * 2)
                                          .clamp(0.0, 1.0),
                                      child: ShaderMask(
                                        shaderCallback: (Rect bounds) {
                                          return LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              widget.hologramColor.withOpacity(
                                                0,
                                              ),
                                              widget.hologramColor.withOpacity(
                                                1,
                                              ),
                                              widget.hologramColor.withOpacity(
                                                0,
                                              ),
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ).createShader(bounds);
                                        },
                                        blendMode: BlendMode.srcIn,
                                        child: SvgPicture.asset(
                                          widget.hologramAsset!,
                                          width: 180,
                                          height: 180,
                                          colorFilter: ColorFilter.mode(
                                            widget.hologramColor,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Second hologram - visible at different angles
                                if (widget.hologramAsset2 != null)
                                  Positioned(
                                    top: 140,
                                    left: 10,
                                    child: Opacity(
                                      // Make it more visible across a wider range of angles
                                      opacity: (1.0 - combinedX.abs() * 1.5)
                                          .clamp(0.0, 1.0),
                                      child: ShaderMask(
                                        shaderCallback: (Rect bounds) {
                                          return LinearGradient(
                                            begin: Alignment.bottomRight,
                                            end: Alignment.topLeft,
                                            colors: [
                                              widget.hologramColor.withOpacity(
                                                1,
                                              ),
                                              widget.hologramColor.withOpacity(
                                                0.5,
                                              ),
                                              widget.hologramColor.withOpacity(
                                                1,
                                              ),
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ).createShader(bounds);
                                        },
                                        blendMode: BlendMode.srcIn,
                                        child: SvgPicture.asset(
                                          widget.hologramAsset2!,
                                          width: 120,
                                          height: 40,
                                          colorFilter: ColorFilter.mode(
                                            Colors.white.withOpacity(0.8),
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
                                    transform:
                                        Matrix4.identity()..rotateY(math.pi),
                                    child: Text(
                                      'Card Back',
                                      style: TextStyle(
                                        color: widget.textColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
