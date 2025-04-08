//
//  WarpBrush.metal
//  CatFiddle
//
//  Created by Moon Davé on 6/15/21.
//

#include <metal_stdlib>
#include "../Common.h"
#include "Brush.metal"


float4 rot(float2 uv, float2 center) {
    float2 d = uv - center;
    float l = length(d);
    return float4(d.y, -d.x, l, l+0.01f);
}

float2 field(float2 uv, float2 center) {
    float2 dir = float2(-normalize(center)); // TODO: make this based on pencil angle?
    float4 rot1 = rot(uv, center);
    float4 rot2 = rot(uv, float2(-center.x,center.y));
    return dir + rot1.xy/(rot1.z*rot1.z+0.1) - rot2.xy/(rot2.z*rot2.z+0.1);
}

#define STEP_COUNT 1
float2 calcNext(float2 uv, float2 center, float t) {
    t /= float(STEP_COUNT);
    for (int i = 0; i < STEP_COUNT; i++) {
        uv += -field(uv, center)*t;
    }
    return uv;
}

float4 getColor(float2 uv, float2 center, float cf, float per, sampler s, texture2d<float> texture) {
    float k1 = 0.007;
    float k2 = 0;

    float t1 = per * cf/4.0;
    float t2 = t1 + per/4.0;

    float2 uv1 = calcNext(uv, center, t1 * k1 + k2);
    float2 uv2 = calcNext(uv, center, t2 * k1 + k2);
    float4 c1 = texture.sample(s, uv1);
    float4 c2 = texture.sample(s, uv2);

    return mix(c1, c2, 1.0);
}

fragment float4 warpBrushFragment(VertexOut in [[stage_in]],
                                  constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]],
                                  constant vector_float2 &center [[ buffer(BufferIndexCenter) ]],
                                  texture2d<float> background [[ texture(TextureIndexBackground)]]) {
    constexpr sampler s(filter::linear);

    float2 uv = in.uv;
    float per = 2.0f;

    float cf = fract(sin(uniforms.time) / per); // should this use time? what does this value do exactly?
    float4 cl = getColor(uv, center, cf, per, s, background);

//    float l = length(field(uv, center));
//    cl = (cl-0.8)*2.+0.8;
//    cl += 0.75*float4(1.0, 0.6, 0.2, 1.)*exp(-1./abs(l+0.1))*2.;
//    cl *= smoothstep(0., 1.,l)+0.2;

    return cl;

}
