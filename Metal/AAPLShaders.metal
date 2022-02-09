/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders for rendering the scene.
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between C code and .metal files.
#import "AAPLShaderTypes.h"

// Per-vertex inputs populated by the vertex buffer you laid out with the `MTLVertexDescriptor` API.
typedef struct
{
    float3 position [[attribute(AAPLVertexAttributePosition)]];
    float2 texCoord [[attribute(AAPLVertexAttributeTexcoord)]];
    half3 normal    [[attribute(AAPLVertexAttributeNormal)]];
} Vertex;

// Vertex shader outputs and per-fragment inputs.
// Includes clip-space position and vertex outputs interpolated by the rasterizer and passed to each
// fragment generated by clip-space primitives.
typedef struct
{
    float4 position [[position]];
    float2 texCoord;
    half3  color;
} TempleShaderInOut;

vertex TempleShaderInOut
templeTransformAndLightingShader(Vertex in [[stage_in]],
                                 constant float4x4      & mvpMatrix [[ buffer(AAPLBufferIndexMVPMatrix) ]],
                                 constant AAPLFrameData & frameData  [[ buffer(AAPLBufferIndexUniforms) ]])
{
    TempleShaderInOut out;

    // Make `in.position` a `float4` to perform 4x4 matrix math on it. Then calculate the position of
    // the vertex in clip space and output the value for clipping and rasterization.
    out.position = mvpMatrix * float4(in.position, 1.0);

    // Pass along the texture coordinate of the vertex for the fragment shader to use to sample from
    // the texture.
    out.texCoord = in.texCoord;

    // Rotate the normal to model space.
    float3 normal = frameData.templeNormalMatrix * float3(in.normal);

    // Light falls off based on how closely aligned the surface normal is to the light direction.
    float nDotL = saturate(dot(normal, frameData.directionalLightInvDirection));

    // The diffuse term is the product of the light color, the surface material reflectance, and the
    // falloff.
    float3 diffuseTerm = frameData.directionalLightColor * nDotL;

    // The ambient contribution is an approximation for global, indirect lighting, and you add it to
    // the calculated lit color value below.

    // Calculate the diffuse contribution from this light (i.e. the sum of the diffuse and ambient * albedo).
    float3 directionalContribution = (diffuseTerm + frameData.ambientLightColor);

    out.color = half3(directionalContribution);

    return out;
}

fragment float4 templeSamplingFragmentShader(TempleShaderInOut in [[stage_in]],
                                             uint primid [[primitive_id]],
                                             constant AAPLFrameData & frameData [[ buffer(AAPLBufferIndexUniforms) ]],
                                             texture2d<half> baseColorMap [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler linearSampler (mip_filter::linear,
                                     mag_filter::linear,
                                     min_filter::linear);

    const half4 baseColorSample = baseColorMap.sample (linearSampler, in.texCoord.xy);

    half3 color = in.color * baseColorSample.xyz;
    half4 output = half4(color, baseColorSample.w);
    if (primid == 0xFFFFFF) // Make sure the compiler doesn't optimize out primid usage
        output = 0;

    // Return the calculated color. Use the alpha channel of `baseColorMap` to set the alpha value.
    return float4(output);
}

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
    float4 eyePos;
} QuadShaderInOut;

vertex QuadShaderInOut
reflectionQuadTransformShader(const device AAPLQuadVertex * vertices [[buffer(AAPLBufferIndexMeshPositions)]],
                              uint                          vertexIndex [[vertex_id]],
                              constant float4x4           & mvpMatrix [[ buffer(AAPLBufferIndexMVPMatrix) ]])
{
    QuadShaderInOut out;

    // Transform by the quad's model-view-projection matrix.
    out.position = mvpMatrix * vertices[vertexIndex].position;

    // Pass the texture coordinate.
    out.texCoord = vertices[vertexIndex].texcoord;

    return out;
}


fragment float4
reflectionQuadFragmentShader(QuadShaderInOut in [[stage_in]],
                             constant AAPLFrameData & frameData [[ buffer(AAPLBufferIndexUniforms) ]],
                             texture2d<float> reflectionMap [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler linearSampler (mip_filter::none,
                                     mag_filter::linear,
                                     min_filter::linear);

    const float4 reflectionSample = reflectionMap.sample(linearSampler, in.texCoord.xy);

    const float4 tintColor = {0, 0, 1, 0};
    const float  tintFactor = 0.02;

    // Add a blue tint to the reflection.
    float4 output = mix(reflectionSample, tintColor, tintFactor);

    return output;
}
