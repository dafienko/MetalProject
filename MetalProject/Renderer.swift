//
//  Renderer.swift
//  MetalProject
//
//  Created by Damien Afienko on 11/18/23.
//

import MetalKit
import Spatial

// vertex information sent to vertex shader stage_in
struct Vertex {
    var position: v3
    var normal: v3
}

typealias v3 = SIMD3<Float>

class Renderer: NSObject {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    let cube: Cube
    let snowman: OBJECTFILE
    
    var time: Float = 0.0;
    
    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        cube = Cube(device: device)
        snowman = OBJECTFILE(device: device, objFilename: "Cubed")
        super.init()
        
        generatePipeline()
    }
    
    private func generatePipeline() {
        let library = device.makeDefaultLibrary()
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_shader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_shader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    func orthographicProjectionMatrix(width: Float, height: Float, depth: Float) -> float4x4 {
            let halfWidth = width / 2.0
            let halfHeight = height / 2.0
            let halfDepth = depth / 2.0

            // Orthographic projection matrix
            return float4x4(columns: (
                SIMD4<Float>(1.0 / halfWidth, 0, 0, 0),
                SIMD4<Float>(0, 1.0 / halfHeight, 0, 0),
                SIMD4<Float>(0, 0, -1.0 / halfDepth, 0),
                SIMD4<Float>(0, 0, 0, 1.0)
            ))
        }
    
    func draw(in view: MTKView) {
        time += 1.0 / Float(view.preferredFramesPerSecond)
        
        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor,
            let pipelineState = pipelineState,
            let depthStencilState = depthStencilState
        else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!;
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setRenderPipelineState(pipelineState)
        
        let projMat = simd_float4x4(ProjectiveTransform3D(
            fovyRadians: 45.0 * (Double.pi / 180.0),
            aspectRatio: view.drawableSize.width / view.drawableSize.height,
            nearZ: 0.1,
            farZ: 100.0)
        )
        
        //cube.render(time: time, encoder: commandEncoder, projMat: projMat)
        snowman.objRender(time: time, encoder: commandEncoder, projMat: projMat)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
