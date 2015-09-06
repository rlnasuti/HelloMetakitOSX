//
//  ViewController.swift
//  HelloMetalOSX
//
//  Created by Robert Nasuti on 9/5/15.
//  Copyright © 2015 Robert Nasuti. All rights reserved.
//

import Cocoa
import MetalKit
import QuartzCore
import CoreVideo

let  AAPLBuffersInflightBuffers: CUnsignedLong  = 3

class ViewController: NSViewController, MTKViewDelegate {
    
    var device: MTLDevice! = nil
    var metalView: MTKView? = nil
    //var metalView: NSView! = nil
    //var metalLayer: CAMetalLayer! = nil
    var vertexBuffer: MTLBuffer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    //var timer: CVDisplayLink! = nil
    var defaultLibrary: MTLLibrary! = nil
    
    var projectionMatrix: matrix_float4x4! = nil
    var viewMatrix:matrix_float4x4! = nil
    
    var frameUniformBuffers: [MTLBuffer]! = nil
    
    let vertexData:[Float] = [
        0.0, 1.0, 0.0,
        -1.0, 0.5, 0.0,
        1.0, -1.0, 0.0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupMetal()
        self.setupView()
        self.loadAssets()
        self.reshape()
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        self.reshape()
    }
    
    func drawInMTKView(view: MTKView) {
        autoreleasepool {
            self.render()
        }
    }
    
    func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.newCommandQueue()
        defaultLibrary = device.newDefaultLibrary()
    }
    
    func setupView() {
        metalView = (self.view as! MTKView)
        metalView!.delegate = self
        metalView!.device = device
    }
    
    func render() {
        self.update()
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        renderPassDescriptor.colorAttachments[0].texture = metalView!.currentDrawable!.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        
        let commandBuffer = commandQueue.commandBuffer()
        
        let renderEncoderOpt: MTLRenderCommandEncoder! = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        if let renderEncoder = renderEncoderOpt {
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
            renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            renderEncoder.endEncoding()
        }
        
        commandBuffer.presentDrawable(metalView!.currentDrawable!)
        commandBuffer.commit()
    }
    
    func matrix_from_perspective_fov_aspectLH(fovY: Float, aspect: Float, nearZ: Float, farZ:  Float) -> matrix_float4x4
    {
        // 1 / tan == cot
        let yscale = 1.0 / tan(fovY * 0.5)
        let xscale: Float = yscale / aspect
        let q = farZ / (farZ - nearZ)
        
        var m: matrix_float4x4 = matrix_float4x4()
        m.columns.0 = [xscale, 0.0, 0.0, 0.0]
        m.columns.1 = [0.0, yscale, 0.0, 0.0]
        m.columns.2 = [0.0, 0.0, q, 1.0]
        m.columns.3 = [0.0, 0.0, q * -nearZ, 0.0]
        
        return m
    }
    
    func reshape() {
        let aspect: Float = Float(fabs(self.view.bounds.size.width / self.view.bounds.size.height))
        projectionMatrix = matrix_from_perspective_fov_aspectLH(65.0 * (3.14159 / 180.0), aspect: aspect, nearZ: 0.1, farZ: 100.0)
        viewMatrix = matrix_identity_float4x4
    }
    
    func loadAssets() {
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: [])
        
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch let pipelineError {
            print("Failed to create pipeline state, error \(pipelineError)")
        }
    }
    
    func update() {
        
    }
    
    
    
}
