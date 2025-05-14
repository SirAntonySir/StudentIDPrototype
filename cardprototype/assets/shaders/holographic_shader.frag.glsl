#version 460 core
#include <flutter/runtime_effect.glsl>

// Input uniforms
uniform vec2 uResolution;  // Dimensions of the card in pixels
uniform vec2 uPointerPos;  // Mouse/tilt position normalized to 0-1 range
uniform vec2 uCenter;      // Dynamic center position for the circular mask

// Output color
out vec4 fragColor;

// Shader parameters
const float WAVE_FREQUENCY = 5.0;
const float POINTER_INFLUENCE = 5.0;
const float COLOR_AMPLITUDE = 0.03;
const float COLOR_MIDPOINT = 0.3;
const float BASE_ALPHA = 0.5;
const float DIAGONAL_FREQ = 5.0;

// Constant rotation angle (in radians)
const float ROTATION_ANGLE = 0.785398; // ~45 degrees

// Rotation function
vec2 rotate(vec2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    
    uv -= 0.5; // Move center
    vec2 rotated = vec2(
        uv.x * c - uv.y * s,
        uv.x * s + uv.y * c
    );
    rotated += 0.5; // Move back
    return rotated;
}

// Circular mask for alpha fading
float circularMask(vec2 uv) {
    // Use the dynamic center position
    vec2 center = uCenter;
    float dist = distance(uv, center);
    float falloff = smoothstep(0.75, 0, dist); // fades out past 0.3 radius
    return falloff;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 rotatedUV = rotate(uv, ROTATION_ANGLE);

    float R = sin(rotatedUV.x * WAVE_FREQUENCY + uPointerPos.x * POINTER_INFLUENCE)
             * COLOR_AMPLITUDE + COLOR_MIDPOINT;

    float G = cos(rotatedUV.y * WAVE_FREQUENCY - uPointerPos.y * POINTER_INFLUENCE)
             * COLOR_AMPLITUDE + COLOR_MIDPOINT;

    float B = sin((rotatedUV.x + rotatedUV.y) * DIAGONAL_FREQ)
             * COLOR_AMPLITUDE + COLOR_MIDPOINT;

    float brightness = (R + G + B) / 5.0;

    // Apply circular falloff to alpha
    float alpha = brightness * BASE_ALPHA * circularMask(uv);

    fragColor = vec4(R, G, B, alpha);
}