//
//  PixelBrush.metal
//  CatFiddle
//
//  Created by Moon Davé on 6/15/21.
//

#include <metal_stdlib>
#include "../Common.h"
#include "Brush.metal"

fragment float4 pixelizerFragment(VertexOut in [[stage_in]],
                                  constant float &brushSize [[ buffer(BufferIndexBrushSize) ]],
                                  texture2d<float> background [[ texture(TextureIndexBackground)]]) {
    constexpr sampler s(filter::linear);
    float size = 1 / 100.0f; // TODO: Maybe make this programmable
    float2 uv = (in.screenCoord * brushSize) * 0.5f + 0.5f;
    return background.sample(s, floor(uv / size) * size);
}
