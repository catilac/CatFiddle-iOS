//
//  Default.swift
//  Brush
//
//  Created by Moon Davé on 12/1/20.
//

import MetalKit

struct DefaultBrush: BasicBrush {

    var texture: MTLTexture
    var renderPipelineState: MTLRenderPipelineState
    var clearStrokePostRender: Bool = true


    init() {
        guard let device = Renderer.device else { fatalError("Renderer not initialized") }

        // initialize texture(s)
        let textureLoader = MTKTextureLoader(device: device)
        do {
            try self.texture = textureLoader.newTexture(
                name: "brush",
                scaleFactor: 1.0,
                bundle: .main,
                options: [MTKTextureLoader.Option.SRGB : false]
            )
        } catch {
            fatalError("Error loading texture")
        }

        self.renderPipelineState = Renderer.createPipelineState(
            label: "Default Brush",
            vertexFunction: "defaultBrushVertex",
            fragmentFunction: "defaultBrushFragment",
            pixelFormat: .bgra8Unorm
        )

    }

    func render(commandBuffer: MTLCommandBuffer, stroke: [Point], layer: Layer, uniforms: Uniforms) {
        guard
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: layer.renderPassDescriptor)
        else { fatalError("Could not create renderEncoder") }
        let numVerts = self.vertices.count
        var uniforms = uniforms

        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        renderEncoder.setFragmentTexture(self.texture, index: Int(TextureIndexStamp.rawValue))
        renderEncoder.setVertexBytes(
            self.vertices,
            length: MemoryLayout<Vertex>.stride * numVerts,
            index: Int(BufferIndexVertices.rawValue)
        )
        
        var color = Settings.color.toSIMD()
        renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD3<Float>>.stride, index: Int(BufferIndexColor.rawValue))

        for p in stroke {

            let translate = float4x4(
                translation: 10 * SIMD3<Float>(p.pos.x * Renderer.aspect, p.pos.y, 0)
            )
            uniforms.modelMatrix = translate * float4x4(scaling: Settings.brushSize)
            renderEncoder.setVertexBytes(
                &uniforms,
                length: MemoryLayout<Uniforms>.stride,
                index: Int(BufferIndexUniforms.rawValue)
            )

            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVerts)
        }

        renderEncoder.endEncoding()
    }

}
