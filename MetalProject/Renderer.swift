//
//  Renderer.swift
//  MetalProject
//
//  Created by Damien Afienko on 11/18/23.
//

import MetalKit
import Spatial

typealias v3 = SIMD3<Float>

// vertex information sent to vertex shader stage_in
struct Vertex {
    var position: v3
    var normal: v3
}

// struct to send to shaders
struct Uniforms {
    var mvMatrix: float4x4 = float4x4(1.0)
    var pMatrix: float4x4 = float4x4(1.0)
    var color: v3 = v3(1.0, 0.0, 0.0)
}

class Renderer: NSObject {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    
    var time: Float = 0.0;
    
    var uniforms = Uniforms()
    
    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        
        generateBuffer()
        generatePipeline()
    }
    
    private func generateBuffer() {
        let v: Float = 1.0
        let right = v3(1, 0, 0)
        let up = v3(0, 1, 0)
        let forward = SIMD3<Float>(0, 0, 1)
        
        let positions: [v3] = [
            v3(v, v, v),
            v3(v, v, -v),
            v3(-v, v, -v),
            v3(-v, v, v),
            
            v3(v, -v, v),
            v3(v, -v, -v),
            v3(-v, -v, -v),
            v3(-v, -v, v),
        ]
        
        var vertices: [Vertex] = []
        var indices: [UInt16] = []
        func add_face(a: v3, b: v3, c: v3, d: v3, normal: v3) {
            let off: UInt16 = UInt16(vertices.count)
            vertices.append(contentsOf: [
                Vertex(position: a, normal: normal),
                Vertex(position: b, normal: normal),
                Vertex(position: c, normal: normal),
                Vertex(position: d, normal: normal),
            ])
            
            let index = [0, 1, 2, 0, 2, 3].map { (i) -> UInt16 in
                return i + off
            }
            indices.append(contentsOf: index)
        }
        
        add_face(a: positions[0], b: positions[1], c: positions[2], d: positions[3], normal: up)
        add_face(a: positions[4], b: positions[5], c: positions[6], d: positions[7], normal: -up)
        
        add_face(a: positions[1], b: positions[0], c: positions[4], d: positions[5], normal: right)
        add_face(a: positions[3], b: positions[2], c: positions[6], d: positions[7], normal: -right)
        
        add_face(a: positions[0], b: positions[3], c: positions[7], d: positions[4], normal: forward)
        add_face(a: positions[1], b: positions[5], c: positions[6], d: positions[2], normal: -forward)
        
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
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        time += 1.0 / Float(view.preferredFramesPerSecond)
        
        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor,
            let vertexBuffer = vertexBuffer,
            let indexBuffer = indexBuffer,
            let pipelineState = pipelineState,
            let depthStencilState = depthStencilState
        else { return }
        
        var modelMat = simd_float4x4(AffineTransform3D.init(translation: Vector3D(x: 0.0, y: 0.0, z: -15.0)))
        modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(0, time, 0), order: .xyz))))
        modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(0, 0, 35.264 * Float.pi / 180), order: .xyz))))
        modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(Float.pi / 4, 0, 0), order: .xyz))))
        
        let viewMat = simd_float4x4(AffineTransform3D.init(translation: Vector3D(x: 0.0, y: 0.0, z: 0.0)))
       
        let projMat = simd_float4x4(ProjectiveTransform3D(
            fovyRadians: 45.0 * (Double.pi / 180.0),
            aspectRatio: view.drawableSize.width / view.drawableSize.height,
            nearZ: 0.1,
            farZ: 100.0)
        )
       
        uniforms.mvMatrix = viewMat.inverse * modelMat
        uniforms.pMatrix = projMat
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor);
        commandEncoder?.setDepthStencilState(depthStencilState)
        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        commandEncoder?.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 36,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
        commandEncoder?.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
