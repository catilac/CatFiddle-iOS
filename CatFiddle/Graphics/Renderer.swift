//
//  Renderer.swift
//  Brush
//
//  Created by Moon Davé on 10/29/20.
//

import MetalKit

final class Renderer: NSObject {
    public var metalView: MTKView
    public var canvas: Canvas?

    static var aspect: Float = 0.0
    static var drawableSize = MTLSize()
    static var device: MTLDevice?
    static var library: MTLLibrary?
    static var queue: MTLCommandQueue?

    var uniforms = Uniforms()

    var renderPipelineState: MTLRenderPipelineState

    override init() {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColorMake(0.4, 0.5, 1.0, 1.0)
        view.isUserInteractionEnabled = true

        guard let device = view.device else { fatalError("Device Not Initialized") }
        guard let queue = device.makeCommandQueue() else { fatalError("Error creating command queue") }
        guard let library = device.makeDefaultLibrary() else { fatalError("Error creating default library" ) }

        Self.device = device
        Self.library = library
        Self.queue = queue
        self.metalView = view
        self.uniforms.viewMatrix = matrix_float4x4(translation: SIMD3<Float>(0, 0, 0)).inverse

        self.renderPipelineState = Renderer.createPipelineState(
            label: "Render output view",
            vertexFunction: "vertexShader",
            fragmentFunction: "fragmentShader",
            pixelFormat: view.colorPixelFormat
        )

        super.init()

        self.metalView.delegate = self
    }

}

// MARK: - MTKViewDelegate Methods

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        Self.aspect = Float(size.width / size.height)
        Self.drawableSize = MTLSize(width: Int(size.width), height: Int(size.height), depth: 1)
        self.uniforms.projectionMatrix = matrix_float4x4(
            orthographic: Rectangle(left: -10 * Self.aspect, right: 10 * Self.aspect, top: 10, bottom: -10),
            near: 100,
            far: 0
        )
        if self.canvas == nil { self.canvas = Canvas(size: size) }
    }

    func draw(in view: MTKView) {
        self.uniforms.time += 0.05
        guard
            let queue = Self.queue,
            let commandBuffer = queue.makeCommandBuffer(),
            let renderDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let canvas = self.canvas
        else { fatalError("Error in draw") }

        canvas.updateCanvas(commandBuffer: commandBuffer, uniforms: self.uniforms)

        guard
            let strokeLayer = canvas.strokeLayer,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor)
        else { return }

        renderEncoder.setRenderPipelineState(self.renderPipelineState)

        let numVerts = canvas.vertices.count
        renderEncoder.setVertexBytes(
            canvas.vertices,
            length: MemoryLayout<Vertex>.stride * numVerts,
            index: Int(BufferIndexVertices.rawValue)
        )

        var uniforms = self.uniforms

        // TODO: - we want to be able to set scale by pinch
        // TODO: - maybe we want to pan, and rotate, too.
        let scale = matrix_float4x4(scaling: 10) // NOTE: This value 10 is actually `cameraSize` or something

        uniforms.modelMatrix = scale
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: Int(BufferIndexUniforms.rawValue))

        renderEncoder.setFragmentTexture(canvas.backgroundLayer?.texture, index: Int(TextureIndexBackground.rawValue))
        renderEncoder.setFragmentTexture(strokeLayer.texture, index: Int(TextureIndexStrokeLayer.rawValue))

        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVerts)

        renderEncoder.endEncoding()


        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

}

// MARK: - Helpers

extension Renderer {

    /// Create new MTLTexture
    /// - Parameters:
    ///   - size: MTLSize
    ///   - pixelFormat: MTLPixelFormat
    ///   - usage: MTLTextureUsage
    ///   - mipmapped: Bool
    /// - Returns: MTLTexture
    static func makeTexture(size: MTLSize, pixelFormat: MTLPixelFormat, usage: MTLTextureUsage) -> MTLTexture {
        guard let device = Self.device else { fatalError("Device not initialized") }

        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = pixelFormat
        descriptor.width = size.width
        descriptor.height = size.height
        descriptor.depth = 1
        descriptor.usage = usage
        guard let texture = device.makeTexture(descriptor: descriptor) else { fatalError("Could not create texture") }
        return texture
    }

    /// Create a Render Pipeline State
    /// - Parameters:
    ///   - label: MTLPipelineState label
    ///   - vertexFunction: Name of the vertex function
    ///   - fragmentFunction: Name of the fragment function
    ///   - pixelFormat: Pixel format for the color attachment
    /// - Returns: MTLRenderPipelineState
    static func createPipelineState(
        label: String,
        vertexFunction: String,
        fragmentFunction: String,
        pixelFormat: MTLPixelFormat
    ) -> MTLRenderPipelineState {

        guard let device = Renderer.device else { fatalError("No device present") }
        guard let library = Renderer.library else { fatalError("No library present") }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        guard let colorAttachment = pipelineStateDescriptor.colorAttachments[0] else {
            fatalError("No color attachment")
        }

        pipelineStateDescriptor.label = label
        pipelineStateDescriptor.vertexFunction = library.makeFunction(name: vertexFunction)
        pipelineStateDescriptor.fragmentFunction = library.makeFunction(name: fragmentFunction)
        colorAttachment.pixelFormat = pixelFormat
        colorAttachment.isBlendingEnabled = true
        colorAttachment.alphaBlendOperation = .add
        colorAttachment.sourceRGBBlendFactor = .one
        colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        colorAttachment.sourceAlphaBlendFactor = .one
        colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            fatalError("Could not create pipeline state")
        }

    }

}

