//
//  Canvas.swift
//  Brush
//
//  Created by Moon Davé on 11/13/20.
//

import MetalKit

/// Canvas stores everything needed to render the canvas. Additionally it manages the strokes.
/// That is, current stroke, existing strokes, etc...
class Canvas {
    var canvasSize = MTLSize()
    var vertices: [Vertex] = []

    var backgroundLayer: Layer?
    var strokeLayer: Layer?

    var currentStroke: Stroke?
    var currentBrush: Brush?

    init(size: CGSize) {
        let ratio: Float = Renderer.aspect
        self.vertices = [
            // Triangle A
            Vertex(position: [-ratio, 1, 0], uv: [0, 0]), // top left
            Vertex(position: [-ratio, -1, 0], uv: [0, 1]), // bottom left
            Vertex(position: [ratio, -1, 0], uv: [1, 1]), // bottom right

            // Triangle B
            Vertex(position: [-ratio, 1, 0], uv: [0, 0]), // top left
            Vertex(position: [ratio, -1, 0], uv: [1, 1]), // bottom right
            Vertex(position: [ratio, 1, 0], uv: [1, 0]), // top right
        ]
        self.initializeTexture(size: size)
    }

    // for merging
    var mergePipelineState: MTLRenderPipelineState?

    private var strokeHasEnded: Bool = false

    func startNewStroke() {
        self.currentBrush = Settings.currentBrush
        self.strokeLayer = Layer(size: self.canvasSize)
        self.currentStroke = Stroke()
    }

    func endStroke() {
        self.strokeHasEnded = true
        self.currentStroke = nil
    }

    func updateCanvas(commandBuffer: MTLCommandBuffer, uniforms: Uniforms) {
        if self.currentStroke != nil {
            self.renderStroke(commandBuffer: commandBuffer, uniforms: uniforms)
        }

        if self.strokeHasEnded {
            self.mergeStrokeLayer(commandBuffer: commandBuffer, uniforms: uniforms)
            self.strokeHasEnded = false
            self.strokeLayer = Layer(size: self.canvasSize)
        }
    }


    // PROBLEM: renderStroke is getting called too much and it's layering everything too much.
    // Everything should only be rendered to the stroke layer once. Or we have to render the strokes in front
    // or something crazy. (Might not be crazy)
    private func renderStroke(commandBuffer: MTLCommandBuffer, uniforms: Uniforms) {
        guard
            let currentStroke = self.currentStroke,
            let strokeLayer = self.strokeLayer
        else { fatalError("Missing currentStroke, or strokeLayer") }

        if let brush = self.currentBrush as? ReadImageBrush {
            guard
                let backgroundLayer = self.backgroundLayer,
                let strokeLayer = self.strokeLayer
            else { fatalError("Missing layers") }
            brush.render(
                commandBuffer: commandBuffer,
                stroke: currentStroke,
                readLayer: backgroundLayer,
                writeLayer: strokeLayer,
                uniforms: uniforms
            )
            // NOTE: we are not clearing the stroke here.
        } else if let brush = self.currentBrush as? BasicBrush {
            brush.render(
                commandBuffer: commandBuffer,
                stroke: currentStroke,
                layer: strokeLayer,
                uniforms: uniforms
            )
            
            // Clear what has already been rendered.
            if brush.clearStrokePostRender {
                self.currentStroke = Stroke()
            }
        }


    }

    private func mergeStrokeLayer(commandBuffer: MTLCommandBuffer, uniforms: Uniforms) {
        guard
            let strokeTexture = self.strokeLayer?.texture,
            let backgroundTexture = self.backgroundLayer?.texture,
            let mergeRenderPassDescriptor = self.backgroundLayer?.renderPassDescriptor,
            let mergePipelineState = self.mergePipelineState,
            let mergeRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: mergeRenderPassDescriptor)
        else { fatalError("Error creating merge render encoder") }

        mergeRenderEncoder.pushDebugGroup("Merge stroke")
        mergeRenderEncoder.setRenderPipelineState(mergePipelineState)
        let numVerts = self.vertices.count
        mergeRenderEncoder.setVertexBytes(
            self.vertices,
            length: MemoryLayout<Vertex>.stride * numVerts,
            index: Int(BufferIndexVertices.rawValue)
        )

        var uniforms = uniforms

        // This needs to reference the camera so we can get the proper model matrix
        let scale = matrix_float4x4(scaling: 10)
        uniforms.modelMatrix = scale
        mergeRenderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: Int(BufferIndexUniforms.rawValue))

        mergeRenderEncoder.setFragmentTexture(backgroundTexture, index: Int(TextureIndexBackground.rawValue))
        mergeRenderEncoder.setFragmentTexture(strokeTexture, index: Int(TextureIndexStrokeLayer.rawValue))

        mergeRenderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVerts)

        mergeRenderEncoder.popDebugGroup()
        mergeRenderEncoder.endEncoding()
    }
}

// MARK: Texture
extension Canvas {

    func initializeTexture(size: CGSize) {
        self.canvasSize = MTLSize(width: Int(size.width), height: Int(size.height), depth: 1)
        self.strokeLayer = Layer(size: self.canvasSize)
        self.backgroundLayer = Layer(size: self.canvasSize)

        guard let backgroundTexture = self.backgroundLayer?.texture else { fatalError("No background texture initialized") }

        // TODO: This may be best done with a blit command encoder `fill` command
        //  -- maybe this needs to go inside of the layer code or something...instance method
        let numColorChannels = 4
        let numBytes = MemoryLayout<UInt8>.stride * numColorChannels * self.canvasSize.width * self.canvasSize.height
        let canvasBytesPtr = UnsafeMutableRawPointer.allocate(byteCount: numBytes, alignment: 0)
        canvasBytesPtr.initializeMemory(as: UInt8.self, repeating: 255, count: numBytes)
        backgroundTexture.replace(
            region: MTLRegion(origin: MTLOrigin(), size: canvasSize),
            mipmapLevel: 0,
            slice: 0,
            withBytes: canvasBytesPtr,
            bytesPerRow: MemoryLayout<UInt8>.stride * numColorChannels * canvasSize.width,
            bytesPerImage: numBytes
        )
        canvasBytesPtr.deallocate()

        self.mergePipelineState = Renderer.createPipelineState(
            label: "Layer merge",
            vertexFunction: "vertexShader",
            fragmentFunction: "fragmentShader",
            pixelFormat: .bgra8Unorm
        )

    }
}
