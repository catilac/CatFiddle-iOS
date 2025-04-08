//
//  DefaultBrush.metal
//  CatFiddle
//
//  Created by Moon Davé on 6/15/21.
//

#include <metal_stdlib>
#include "../Common.h"
#include "Brush.metal"

vertex VertexOut
defaultBrushVertex(uint vertexId [[vertex_id]],
                   constant Vertex *vertices [[buffer(BufferIndexVertices)]],
                   constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]]) {
    Vertex inVertex = vertices[vertexId];
    VertexOut out;

    float4 inPos = float4(inVertex.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * inPos;

    out.screenCoord = out.position.xy;
    out.screenCoord.y *= -1.0f;

    out.uv = inVertex.uv;

    return out;
}

fragment float4 defaultBrushFragment(VertexOut in [[stage_in]],
                                     constant vector_float4 &strokeColor [[buffer(BufferIndexColor)]],
                                     texture2d<float> img [[ texture(TextureIndexStamp) ]]) {
    constexpr sampler s(filter::linear);
    float4 texColor = img.sample(s, in.uv);
    texColor.rgb = strokeColor.rgb;
    return texColor;
}
