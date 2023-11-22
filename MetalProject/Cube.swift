//
//  Cube.swift
//  MetalProject
//
//  Created by Damien Afienko on 11/20/23.
//

import MetalKit
import Spatial

// struct to send to shaders
struct Uniforms {
    var mvMatrix: float4x4 = float4x4(1.0)
    var pMatrix: float4x4 = float4x4(1.0)
    var color: v3 = v3(1.0, 0.0, 0.0)
}
//just gets the name of the material as of right now not assigning or grabbing any color
struct Material {
    var name: String
}

struct OBJModel {
    var vertices: [v3] = []
    var normals: [v3] = []
    var indices: [UInt16] = []
    var materials: [Material] = []

    init(contentsOfURL url: URL) {
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let lines = data.components(separatedBy: .newlines)

            for line in lines {
                let components = line.components(separatedBy: " ")

                switch components[0] {
                case "v":
                    // Parse vertex position
                    let x = Float(components[1])!
                    let y = Float(components[2])!
                    let z = Float(components[3])!
                    vertices.append(v3(x, y, z))

                case "vn":
                    // Parse vertex normal
                    let nx = Float(components[1])!
                    let ny = Float(components[2])!
                    let nz = Float(components[3])!
                    normals.append(v3(nx, ny, nz))

                case "f":
                    // Parse face indices
                    for i in 1..<components.count {
                        let indices = components[i].components(separatedBy: "/")
                        let vertexIndex = UInt16(indices[0])! - 1
                        self.indices.append(vertexIndex)
                    }

                case "usemtl":
                    // Parse material properties
                    let materialName = components[1]
                    let material = Material(name: materialName)
                    materials.append(material)

                default:
                    break
                }
            }
            print("Vertices: \(vertices)")
                        print("Normals: \(normals)")
                        print("Indices: \(indices)")
                        print("Materials: \(materials)")
        } catch {
            print("Error reading OBJ file: \(error)")
        }
    }
}


class Cube: NSObject {
    var uniforms = Uniforms()
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    
    init(device: MTLDevice, objFilename: String?) {
        super.init()

        if let filename = objFilename {
            // Load OBJ file and generate buffers
            if let url = Bundle.main.url(forResource: filename, withExtension: "obj") {
                generateBufferFromOBJ(device: device, objURL: url)
            } else {
                print("Error: Unable to find the OBJ file with name '\(filename)'.")
            }
        } else {
            // Generate cube buffers if no OBJ file provided
            generateBuffer(device: device)
        }
    }
    
    private func generateBufferFromOBJ(device: MTLDevice, objURL: URL) {
            // Use the OBJModel structure to load OBJ file and generate buffers
            let objModel = OBJModel(contentsOfURL: objURL)

            vertexBuffer = device.makeBuffer(
                bytes: objModel.vertices,
                length: objModel.vertices.count * MemoryLayout<Vertex>.stride,
                options: []
            )

            indexBuffer = device.makeBuffer(
                bytes: objModel.indices,
                length: objModel.indices.count * MemoryLayout<UInt16>.size,
                options: []
            )
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
    
    public func render(time: Float, encoder: MTLRenderCommandEncoder, projMat: float4x4) {
        guard
            let vertexBuffer = vertexBuffer,
            let indexBuffer = indexBuffer
        else { return }
        
        var modelMat = simd_float4x4(AffineTransform3D.init(translation: Vector3D(x: 0.0, y: 0.0, z: -15.0)))
        modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(0, time, 0), order: .xyz))))
        modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(0, 0, 35.264 * Float.pi / 180), order: .xyz))))
        modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(Float.pi / 4, 0, 0), order: .xyz))))
        
        let viewMat = simd_float4x4(AffineTransform3D.init(translation: Vector3D(x: 0.0, y: 0.0, z: 0.0)))
       
        uniforms.mvMatrix = viewMat.inverse * modelMat
        uniforms.pMatrix = projMat
        
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
