//
//  Shader.metal
//  MetalProject
//
//  Created by Damien Afienko on 11/18/23.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 mvpMatrix;
};

struct VertexIn {
    float4 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float4 color;
};

vertex VertexOut vertex_shader(const VertexIn vertexIn [[ stage_in ]], constant Uniforms &uniforms [[ buffer(1) ]]) {
    VertexOut vertexOut;
    vertexOut.position = uniforms.mvpMatrix * vertexIn.position;
    vertexOut.color = vertexIn.color;
    
    return vertexOut;
}

fragment half4 fragment_shader(VertexOut vertexIn [[ stage_in ]]) {
    return half4(vertexIn.color);
}
