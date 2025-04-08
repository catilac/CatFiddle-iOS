//
//  Shader.metal
//  Brush
//
//  Created by Moon Davé on 10/30/20.
//

#include <metal_stdlib>

#include "Common.h"

using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut
vertexShader(uint vertexId [[vertex_id]],
             constant Vertex *vertices [[buffer(BufferIndexVertices)]],
             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]]) {

    Vertex inVertex = vertices[vertexId];
    VertexOut out;

    float4 inPos = float4(inVertex.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * inPos;

    out.uv = inVertex.uv;

    return out;
}

// TODO: Seriously rename this
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> backgroundImg [[ texture(TextureIndexBackground) ]],
                               texture2d<float> strokeImg [[ texture(TextureIndexStrokeLayer)]]) {
    constexpr sampler s(filter::linear);
    float4 bgColor = backgroundImg.sample(s, in.uv);
    float4 strokeColor = strokeImg.sample(s, in.uv);

    // Alpha Blending
    //result = source.RGB + (dest.RGB * (1 - source.A))
    float3 rgb = strokeColor.rgb + (bgColor.rgb * (1 - strokeColor.a));
    float alpha = strokeColor.a + (bgColor.a * (1 - strokeColor.a));
    return float4(rgb, alpha);

}
