import MetalKit
import Spatial

// vertex information sent to vertex shader stage_in
struct Vertex {
    var position: v3
    var normal: v3
    var color: v3
}

// struct to send to shaders
struct Uniforms {
    var mvMatrix: float4x4 = float4x4(1.0)
    var pMatrix: float4x4 = float4x4(1.0)
}

typealias v2 = SIMD2<Float>
typealias v3 = SIMD3<Float>

protocol Renderable {
    func render(time: Float, encoder: MTLRenderCommandEncoder, viewMatrix: float4x4, projectionMatrix: float4x4)
}

class Renderer: NSObject {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    var objects: [Renderable] = []
    let camera: Camera = Camera(viewportSize: v2(1.0, 1.0))
    
    var time: Float = 0.0;
    
    init(device: MTLDevice, viewportSize: v2) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        
        camera.viewportSize = viewportSize
        
        objects.append(Model(
            device: device,
            objFile: Bundle.main.url(forResource: "Snowman", withExtension: "obj")!,
            mtlFile: Bundle.main.url(forResource: "SnowmanMaterial", withExtension: "lib")!
        ))
        
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
        vertexDescriptor.attributes[1].offset = MemoryLayout<v3>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].format = .float3
        vertexDescriptor.attributes[2].offset =  vertexDescriptor.attributes[1].offset + MemoryLayout<v3>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.viewportSize = v2(Float(size.width), Float(size.height))
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
        
        for object in objects {
            object.render(
                time: time,
                encoder: commandEncoder,
                viewMatrix: camera.viewMatrix,
                projectionMatrix: camera.projectionMatrix
            )
        }
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
