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
    var materialNames: [String] = []
    var materialColors: [v3] = []
    var materialIndex = -1

    // Properties to store the maximum absolute values
    var maxVertexValues: v3 = v3(repeating: 0.0)
    var minVertexValues: v3 = v3(repeating: 0.0)

    init(contentsOfURL url: URL, materialPath: URL) {
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let lines = data.components(separatedBy: .newlines)

            let materialLibData = try String(contentsOf: materialPath, encoding: .utf8)
            let materialLibLines = materialLibData.components(separatedBy: .newlines)

            var currentMaterialName = "Default"  // Default material name

                    for materialLibLine in materialLibLines {
                        let materialComponents = materialLibLine.components(separatedBy: " ").filter { !$0.isEmpty }
                        if !materialComponents.isEmpty {
                            switch materialComponents.first?.trimmingCharacters(in: .whitespaces) {
                            case "newmtl":
                                // New material definition found, update the currentMaterialName
                                if materialComponents.count >= 2 {
                                    currentMaterialName = materialComponents[1]
                                    materialNames.append(currentMaterialName)
                                }
                            case "Kd":
                                // Parse the RGB color from the material.lib file
                                let r = Float(materialComponents[1])!
                                let g = Float(materialComponents[2])!
                                let b = Float(materialComponents[3])!
                                materialColors.append(v3(r, g, b))
                            default:
                                break
                            }
                        }
                    }

                    // Create Material instances and append them to the materials array
            print(materialNames)
            print(materialColors)
            for i in 0..<materialNames.count {
                var materialAPP = Material(name: materialNames[i],color: materialColors[i])
                materials.append(materialAPP)
                
            }
            print(materials)
            for line in lines {
                let components = line.components(separatedBy: " ").filter { !$0.isEmpty }
                //if components equals nothing dont run the switch
                if !components.isEmpty {
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
                        //if there are 3 components
                        if components.count == 4 {
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
                                Vertex(position: positions[a-1], normal: normals[d-1],color: materials[materialIndex].color),
                                Vertex(position: positions[b-1], normal: normals[d-1],color: materials[materialIndex].color),
                                Vertex(position: positions[c-1], normal: normals[d-1],color: materials[materialIndex].color),
                            ])
                            
                            let index = [0, 1, 2].map { (i) -> UInt16 in
                                return i + off
                            }
                            indices.append(contentsOf: index)
                        }
                        if components.count == 5{
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
                            let dComponent = components[4].components(separatedBy: "/")
                            guard let d = Int(dComponent[0]) else {
                                print(components)
                                fatalError("Invalid face definition in the OBJ file.")
                            }
                            
                            let eComponent = components[3].components(separatedBy: "/")
                            guard let e = Int(eComponent.last ?? "") else {
                                fatalError("Invalid face definition in the OBJ file.")
                            }
                            
                            let off: UInt16 = UInt16(vertices.count)
                            vertices.append(contentsOf: [
                                Vertex(position: positions[a-1], normal: normals[e-1],color: materials[materialIndex].color),
                                Vertex(position: positions[b-1], normal: normals[e-1],color: materials[materialIndex].color),
                                Vertex(position: positions[c-1], normal: normals[e-1],color: materials[materialIndex].color),
                                Vertex(position: positions[d-1], normal: normals[e-1],color: materials[materialIndex].color),
                            ])
                            
                            let index = [0, 1, 2,0,2,3].map { (i) -> UInt16 in
                                return i + off
                            }
                            indices.append(contentsOf: index)
                            
                        }
                        
                        
                    case "usemtl":
                        if let materialName = components.last {
                            if let index = materialNames.firstIndex(of: materialName) {
                                materialIndex = index
                            }
                        }
                        
                    default:
                        break
                    }
                }
            }

            //print(materialIndices)
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
        
    init(device: MTLDevice, objFilename: String, materialFilename: String) {
            
            
            super.init()

            if let url = Bundle.main.url(forResource: objFilename, withExtension: "obj") {
                if let matURL = Bundle.main.url(forResource: materialFilename, withExtension: "lib") {
                    objModel = generateBufferFromOBJ(device: device, objURL: url,materialURL: matURL)
                } else {
                    print("Error: Unable to find the lib file with name '\(materialFilename)'.")
                }
            } else {
                print("Error: Unable to find the OBJ file with name '\(objFilename)'.")
            }
        }
    
    private func generateBufferFromOBJ(device: MTLDevice, objURL: URL, materialURL:URL)-> OBJModel {
            // Use the OBJModel structure to load OBJ file and generate buffers
            let objModel = OBJModel(contentsOfURL: objURL, materialPath: materialURL)
            
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
        
        let modelMat = simd_float4x4(AffineTransform3D.init(rotation: Rotation3D(eulerAngles: EulerAngles(angles: simd_float3(0, time, 0), order: .xyz))))
        
        let viewMat = simd_float4x4(AffineTransform3D.init(translation: Vector3D(x: 0.0, y: objModel.maxVertexValues.y/2, z: objModel.maxVertexValues.z)))
        
        uniforms.mvMatrix = viewMat.inverse * modelMat
        uniforms.pMatrix = projMat
        
        
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
