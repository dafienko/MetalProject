//
//  Shader.metal
//  MetalProject
//
//  Created by Damien Afienko on 11/18/23.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 mvMatrix;
    float4x4 pMatrix;
    float3 color;
};

struct VertexIn {
    float3 position [[ attribute(0) ]];
    float3 normal [[ attribute(1) ]];
    float3 color [[ attribute(2) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 normal;
    float3 color;
};

vertex VertexOut vertex_shader(const VertexIn vertexIn [[ stage_in ]], constant Uniforms &uniforms [[ buffer(1) ]]) {
    VertexOut vertexOut;
    vertexOut.position = uniforms.pMatrix * uniforms.mvMatrix * float4(vertexIn.position, 1.0);
    vertexOut.normal = float3((uniforms.mvMatrix * float4(vertexIn.normal, 0.0)).xyz);
    vertexOut.color = vertexIn.color;
    
    return vertexOut;
}

constant float3 LIGHT_DIR = float3(1.0, -3, -1.8);
constant float ambient = .3;

fragment half4 fragment_shader(VertexOut vertexIn [[ stage_in ]]) {
    float diffuse = max(ambient, dot(normalize(vertexIn.normal), -normalize(LIGHT_DIR)));
    half3 color = (half3)vertexIn.color * diffuse;
    return half4(color.xyz, 1);
}
