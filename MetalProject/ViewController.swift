import UIKit
import MetalKit

class ViewController: UIViewController {
    @IBOutlet weak var metalView: MTKView!
    
    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        
        renderer = Renderer(
            device: metalView.device!,
            viewportSize: v2(Float(metalView.drawableSize.width), Float(metalView.drawableSize.height))
        )
        metalView.delegate = renderer
    }
}
