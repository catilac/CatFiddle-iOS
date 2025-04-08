//
//  Brush.metal
//  CatFiddle
//
//  Created by Moon Davé on 11/9/20.
//

#include <metal_stdlib>
#include "../Common.h"
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 screenCoord;
    float2 uv;
};


