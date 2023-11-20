//
//  ViewController.swift
//  MetalProject
//
//  Created by Damien Afienko on 11/18/23.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    @IBOutlet weak var metalView: MTKView!
    
    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        renderer = Renderer(device: metalView.device!)
        metalView.delegate = renderer
    }
}
