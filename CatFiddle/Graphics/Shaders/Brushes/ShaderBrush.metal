//
//  ShaderBrush.metal
//  CatFiddle
//
//  Created by Moon Davé on 6/15/21.
//

#include <metal_stdlib>
#include "../Common.h"
#include "Brush.metal"

extern float snoise(float4 v);

float circle(float2 pos, float radius) {
    return length(pos) - radius;
}

fragment float4 shaderBrushFragment(VertexOut in [[stage_in]],
                                    constant vector_float4 &strokeColor [[buffer(BufferIndexColor)]],
                                    constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]]) {
    float2 uv = -1 + 2 * in.uv;
    float d = smoothstep(0.1, 0.0, circle(uv, 0.6) + snoise(float4(uv.x, uv.y, uniforms.time, uv.x*uv.y)));
    if (d < 0.1) { discard_fragment(); }
    return float4(d * strokeColor.rgb, strokeColor.a);
}
