//
//  BlobBrush.metal
//  CatFiddle
//
//  Created by Moon Davé on 6/15/21.
//

#include <metal_stdlib>
#include "../Common.h"
#include "Brush.metal"

struct ControlPoint {
  float2 position [[ attribute(0) ]];
};

extern float fbm (float2 st);

// MARK: - tesselation_main

kernel void tessellation_main(constant float* edge_factors      [[ buffer(BufferIndexEdgeFactors) ]],
                              constant float* inside_factors   [[ buffer(BufferIndexInsideFactors) ]],
                              device MTLQuadTessellationFactorsHalf* factors [[ buffer(BufferIndexTessellationFactors) ]],
                              uint pid [[ thread_position_in_grid ]])
{
    factors[pid].edgeTessellationFactor[0] = edge_factors[0];
    factors[pid].edgeTessellationFactor[1] = edge_factors[0];
    factors[pid].edgeTessellationFactor[2] = edge_factors[0];
    factors[pid].edgeTessellationFactor[3] = edge_factors[0];

    factors[pid].insideTessellationFactor[0] = inside_factors[0];
    factors[pid].insideTessellationFactor[1] = inside_factors[0];
}

// MARK: - blobBrushVertex

[[ patch(quad, 16) ]]
vertex VertexOut
blobBrushVertex(patch_control_point<ControlPoint> control_points [[ stage_in ]],
                constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]],
                uint pid [[ patch_id ]],
                float2 patch_coord [[ position_in_patch ]]) {
    VertexOut out;

    float time = uniforms.time;

    float u = patch_coord.x;
    float v = patch_coord.y;

    float2 c00 = control_points[0].position;
    float2 c01 = control_points[1].position;
    float2 c02 = control_points[2].position;
    float2 c03 = control_points[3].position;
    float2 c10 = control_points[4].position;
    float2 c11 = control_points[5].position;
    float2 c12 = control_points[6].position;
    float2 c13 = control_points[7].position;
    float2 c20 = control_points[8].position;
    float2 c21 = control_points[9].position;
    float2 c22 = control_points[10].position;
    float2 c23 = control_points[11].position;
    float2 c30 = control_points[12].position;
    float2 c31 = control_points[13].position;
    float2 c32 = control_points[14].position;
    float2 c33 = control_points[15].position;

    const float4x4 B(
        -1.0,  3.0, -3.0, 1.0,
         3.0, -6.0,  3.0, 0.0,
        -3.0,  3.0,  0.0, 0.0,
         1.0,  0.0,  0.0, 0.0
    );

    float4x4 Bt = transpose(B);

    float4x4 Gx(
        c00.x, c01.x, c02.x, c03.x,
        c10.x, c11.x, c12.x, c13.x,
        c20.x, c21.x, c22.x, c23.x,
        c30.x, c31.x, c32.x, c33.x
    );

    float2 q = float2(fbm(patch_coord),
                      fbm(patch_coord + float2(1.9, 2.13)));

    float2 r = 10*float2(fbm(3.0 * q + patch_coord + float2(sin(time) + 1, cos(time/10000))),
                      fbm(3.0 * q + patch_coord + float2(8.1, -0.5)));

    Gx += float4x4(
        fbm(c00+r), fbm(c01+r), fbm(c02+r), fbm(c03+r),
        fbm(c10+r), fbm(c11+r), fbm(c12+r), fbm(c13+r),
        fbm(c20+r), fbm(c21+r), fbm(c22+r), fbm(c23+r),
        fbm(c30+r), fbm(c31+r), fbm(c32+r), fbm(c33+r)
    );

    float4x4 Gy(
        c00.y, c01.y, c02.y, c03.y,
        c10.y, c11.y, c12.y, c13.y,
        c20.y, c21.y, c22.y, c23.y,
        c30.y, c31.y, c32.y, c33.y
    );

    Gy -= float4x4(
        fbm(c00+r), fbm(c01+r), fbm(c02+r), fbm(c03+r),
        fbm(c10+r), fbm(c11+r), fbm(c12+r), fbm(c13+r),
        fbm(c20+r), fbm(c21+r), fbm(c22+r), fbm(c23+r),
        fbm(c30+r), fbm(c31+r), fbm(c32+r), fbm(c33+r)
    );

    float4 S(u * u * u, u * u, u, 1);
    float4 T(v * v * v, v * v, v, 1);

    float x = dot(S, Bt * Gx * B * T);
    float y = dot(S, Bt * Gy * B * T);

    float4 position = float4(x, y, 0.0, 1.0);

    out.uv = patch_coord;
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * position;

    return out;
}


// MARK: - blobBrushFragment

fragment float4 blobBrushFragment(VertexOut in [[stage_in]],
                                  constant Dynamic &dynamic [[ buffer(BufferIndexDynamic) ]],
                                  constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]]) {

    // Maybe make these parameters user controlled
    float3 a = float3(0.5);
    float3 b = float3(0.5);
    float3 c = float3(2, 1, 0);
    float3 d = float3(0.5, 0.2, 0.25);

    float3 color;

    // TODO: could this be pressure controlled?
    switch (dynamic) {
        case DynamicTime:
            color = a + b * cos(2*M_PI_F*(c * uniforms.time/10.0f + d));
            break;
        case DynamicPressure:
            color = a + b * cos(2*M_PI_F*(c * uniforms.pressure/10.0f + d));
            break;
        case DynamicVelocity:
            color = a + b * cos(2*M_PI_F*(c * length(uniforms.velocity)/10.0f + d));
            break;
        case DynamicAngle:
            color = a + b * cos(2*M_PI_F*(c * uniforms.angle/10.0f + d));
            break;
    }

    return float4(color, 1.0);
}
