import MetalKit
import Spatial

class Cube: NSObject {
    var uniforms = Uniforms()
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    
    init(device: MTLDevice) {
        super.init()
        
        generateBuffer(device: device)
    }
    
    private func generateBuffer(device: MTLDevice) {
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
                Vertex(position: a, normal: normal, color: v3(1.0, 0.0, 0.0)),
                Vertex(position: b, normal: normal, color: v3(0.0, 1.0, 0.0)),
                Vertex(position: c, normal: normal, color: v3(0.0, 0.0, 1.0)),
                Vertex(position: d, normal: normal, color: v3(1.0, 1.0, 1.0)),
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
}

extension Cube: Renderable {
    func render(time: Float, encoder: MTLRenderCommandEncoder, viewMatrix: float4x4, projectionMatrix: float4x4) {
        guard
            let vertexBuffer = vertexBuffer,
            let indexBuffer = indexBuffer
        else { return }
        
        var modelMat = simd_float4x4(AffineTransform3D.init(translation: Vector3D(x: 0.0, y: 0.0, z: -15.0)))
        modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(0, time, 0), order: .xyz))))
        modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(0, 0, 35.264 * Float.pi / 180), order: .xyz))))
        modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(Float.pi / 4, 0, 0), order: .xyz))))
        
        let viewMat = simd_float4x4(AffineTransform3D.init(translation: Vector3D(x: 0.0, y: 0.0, z: 0.0)))
       
        uniforms.mvMatrix = viewMatrix * modelMat
        uniforms.pMatrix = projectionMatrix
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 36,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
    }
}
