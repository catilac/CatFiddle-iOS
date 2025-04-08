//
//  Common.h
//  Brush
//
//  Created by Moon Davé on 10/30/20.
//

#ifndef Common_h
#define Common_h

#include <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    float time;
    float pressure;
    float angle;
    vector_float2 velocity;
} Uniforms;

typedef struct {
    vector_float3 position;
    vector_float2 uv;
} Vertex;

typedef enum {
    BufferIndexVertices = 0,
    BufferIndexUniforms,
    BufferIndexDynamic,
    BufferIndexColor,
    BufferIndexEdgeFactors,
    BufferIndexInsideFactors,
    BufferIndexTessellationFactors,
    BufferIndexCenter,
    BufferIndexBrushSize,
} BufferIndices;

typedef enum {
    TextureIndexBackground = 0,
    TextureIndexStrokeLayer,
    TextureIndexStamp
} TextureIndices;

typedef enum {
    DynamicTime = 0,
    DynamicPressure,
    DynamicVelocity,
    DynamicAngle
} Dynamic;

#endif /* Common_h */
