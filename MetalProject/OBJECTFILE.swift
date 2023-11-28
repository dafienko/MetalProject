//
//  OBJECTFILE.swift
//  MetalProject
//
//  Created by Shane D. Bailey on 11/28/23.
//


import MetalKit
import Spatial

// struct to send to shaders
//just gets the name of the material as of right now not assigning or grabbing any color
struct Material {
    var name: String
    var color: v3
}

struct OBJModel {
    var positions: [v3] = []
    var vertices: [Vertex] = []
    var normals: [v3] = []
    var indices: [UInt16] = []
    var materials: [Material] = []

    // Properties to store the maximum absolute values
    var maxVertexValues: v3 = v3(0.0)
    var minVertexValues: v3 = v3(0.0)

    init(contentsOfURL url: URL) {
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let lines = data.components(separatedBy: .newlines)

            //var currentMaterial = Material(name: "Default", color: v3(1.0, 1.0, 1.0))

            for line in lines {
                let components = line.components(separatedBy: " ")

                switch components[0] {
                case "v":
                    // Parse vertex position
                    let x = Float(components[1])!
                    let y = Float(components[2])!
                    let z = Float(components[3])!
                    let vertex = v3(x, y, z)
                    positions.append(vertex)

                    // Update maxVertexValues
                    maxVertexValues.x = max(maxVertexValues.x, abs(vertex.x))
                    maxVertexValues.y = max(maxVertexValues.y, abs(vertex.y))
                    maxVertexValues.z = max(maxVertexValues.z, abs(vertex.z))
                    
                    minVertexValues.x = min(maxVertexValues.x, abs(vertex.x))
                    minVertexValues.y = min(maxVertexValues.y, abs(vertex.y))
                    minVertexValues.z = min(maxVertexValues.z, abs(vertex.z))

                case "vn":
                    // Parse vertex normal
                    let nx = Float(components[1])!
                    let ny = Float(components[2])!
                    let nz = Float(components[3])!
                    normals.append(v3(nx, ny, nz))

                case "f":
                    let aComponent = components[1].components(separatedBy: "/")
                    guard let a = Int(aComponent[0]) else {
                        fatalError("Invalid face definition in the OBJ file.")
                    }
                    let bComponent = components[2].components(separatedBy: "/")
                    guard let b = Int(bComponent[0]) else {
                        fatalError("Invalid face definition in the OBJ file.")
                    }
                    let cComponent = components[3].components(separatedBy: "/")
                    guard let c = Int(cComponent[0]) else {
                        fatalError("Invalid face definition in the OBJ file.")
                    }
                    
                    let dComponent = components[3].components(separatedBy: "/")
                    guard let d = Int(dComponent.last ?? "") else {
                        fatalError("Invalid face definition in the OBJ file.")
                    }
                    
                    let off: UInt16 = UInt16(vertices.count)
                    vertices.append(contentsOf: [
                        Vertex(position: positions[a-1], normal: normals[d-1]),
                        Vertex(position: positions[b-1], normal: normals[d-1]),
                        Vertex(position: positions[c-1], normal: normals[d-1]),
                    ])
                    
                    let index = [0, 1, 2].map { (i) -> UInt16 in
                        return i + off
                    }
                    indices.append(contentsOf: index)
    
                    
                case "usemtl":
                    let materialName = components[1]
                    if let existingMaterial = materials.first(where: { $0.name == materialName }) {
                    } else {
                        // Create a new material with a default color
                        let newMaterial = Material(name: materialName, color: v3(1.0, 0.0, 0.0))
                        materials.append(newMaterial)
                    }

                default:
                    break
                }
            }

            print("MaxVertices: \(maxVertexValues)")

        } catch {
            print("Error reading OBJ file: \(error)")
        }
    }
}

class OBJECTFILE: NSObject{
    var uniforms = Uniforms()
        var vertexBuffer: MTLBuffer?
        var indexBuffer: MTLBuffer?
        var objModel: OBJModel?
        
        init(device: MTLDevice, objFilename: String) {
            
            
            super.init()

            if let url = Bundle.main.url(forResource: objFilename, withExtension: "obj") {
                objModel = generateBufferFromOBJ(device: device, objURL: url)
            } else {
                print("Error: Unable to find the OBJ file with name '\(objFilename)'.")
            }
        }
    
    private func generateBufferFromOBJ(device: MTLDevice, objURL: URL)-> OBJModel {
            // Use the OBJModel structure to load OBJ file and generate buffers
            var objModel = OBJModel(contentsOfURL: objURL)
            let scaleFactor: Float = 0.01
            objModel.positions = objModel.positions.map { $0 * scaleFactor }
            

            
            vertexBuffer = device.makeBuffer(
                bytes: objModel.vertices,
                length: objModel.vertices.count * MemoryLayout<Vertex>.stride,
                options: []
            )
        print("Indicies count")
        print(objModel.indices.count)
            indexBuffer = device.makeBuffer(
                bytes: objModel.indices,
                length: objModel.indices.count * MemoryLayout<UInt16>.size,
                options: []
            )
            
            return objModel
        }
    
    public func objRender(time: Float, encoder: MTLRenderCommandEncoder, projMat: float4x4) {
                guard
                    let vertexBuffer = vertexBuffer,
                    let indexBuffer = indexBuffer,
                    let objModel = objModel
                else { return }
                
                // Calculate the bounding box center and size
                //let boundingBoxCenter = (objModel.maxVertexValues + objModel.minVertexValues) / 2.0
                let boundingBoxSize = objModel.maxVertexValues - objModel.minVertexValues
            
                let boundingBoxCenter = (objModel.maxVertexValues + objModel.minVertexValues) / 2.0

            
                var modelMat = simd_float4x4(AffineTransform3D.init(translation: Vector3D(x: 0.0, y: 0.0, z: -15.0)))
                    modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(0, time, 0), order: .xyz))))
                    modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(0, 0, 35.264 * Float.pi / 180), order: .xyz))))
                    modelMat *= simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(Float.pi / 4, 0, 0), order: .xyz))))
                // Define a distance from the object based on its size or any other suitable metric
                let viewMat = simd_float4x4(AffineTransform3D.init(translation: Vector3D(x: 0.0, y: 0.0, z: 0.0)))
                   
                uniforms.mvMatrix = viewMat.inverse * modelMat
                uniforms.pMatrix = projMat
                
                // Set buffers and draw
                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
                encoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: objModel.indices.count,
                    indexType: .uint16,
                    indexBuffer: indexBuffer,
                    indexBufferOffset: 0
                )
            }
    
}
