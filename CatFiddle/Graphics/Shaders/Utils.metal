//
//  Utils.metal
//  CatFiddle
//
//  Created by Moon Davé on 6/14/21.
//

#include <metal_stdlib>
using namespace metal;

// from book of shaders
float random (float2 st) {
    return fract(sin(dot(st.xy,
                         float2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    float d = random(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 1
float fbm (float2 st) {
    float v = 0.0;
    float a = 0.5;
    float2 shift(100.0);
    // Rotate to reduce axial bias
    float2x2 rot(cos(0.5), sin(0.5),
                -sin(0.5), cos(0.50));
    for (int i = 0; i < OCTAVES; ++i) {
        v += a * noise(st);
        st = rot * st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}
