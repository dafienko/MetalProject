import MetalKit
import Spatial

class Camera: NSObject {
    var transform: float4x4 = float4x4(1.0)
    var fov: Float = 45.0
    var viewportSize: v2
    
    var viewMatrix: float4x4 {
        get {
            return transform.inverse
        }
    }
    
    var projectionMatrix: float4x4 {
        get {
            return simd_float4x4(ProjectiveTransform3D(
                fovyRadians: Double(fov) * (Double.pi / 180.0),
                aspectRatio: Double(viewportSize.x / viewportSize.y),
                nearZ: 0.1,
                farZ: 100.0
            ))
        }
    }
    
    init(viewportSize: v2) {
        self.viewportSize = viewportSize
        super.init()
    }
}
