//
//  Renderer.swift
//  MetalProject
//
//  Created by Damien Afienko on 11/18/23.
//

import MetalKit

struct Vertex {
    var position: SIMD3<Float>;
    var color: SIMD4<Float>;
}

class Renderer: NSObject {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    
    var time: Float = 0.0;
    
    struct Uniforms {
        var offset: Float = 0.0;
    }
    
    var uniforms = Uniforms()
    
    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        
        generateBuffer()
        generatePipeline()
    }
    
    private func generateBuffer() {
        let x: Float = 0.8
        let vertices: [Vertex] = [
            Vertex(position: SIMD3<Float>(x, x, 0.0), color: SIMD4<Float>(1.0, 0.0, 1.0, 1.0)), // top right
            Vertex(position: SIMD3<Float>(-x, x, 0.0), color: SIMD4<Float>(0.0, 0.0, 1.0, 1.0)), // top left
            Vertex(position: SIMD3<Float>(-x, -x, 0.0), color: SIMD4<Float>(0.0, 1.0, 0.0, 1.0)), // bottom left
            Vertex(position: SIMD3<Float>(x, -x, 0.0), color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0)), // bottom right
        ]
        
        let indices: [UInt16] = [
            0, 1, 2,
            0, 2, 3
        ]
        
        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<Vertex>.stride,
            options: []
        )
        
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.size,
            options: []
        )
    }
    
    private func generatePipeline() {
        let library = device.makeDefaultLibrary()
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_shader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_shader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        time += 1.0 / Float(view.preferredFramesPerSecond)
        
        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor,
            let vertexBuffer = vertexBuffer,
            let indexBuffer = indexBuffer,
            let pipelineState = pipelineState
        else { return }
        
        uniforms.offset = abs(sin(time));
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor);
        
        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        commandEncoder?.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 6,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
        
        commandEncoder?.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
