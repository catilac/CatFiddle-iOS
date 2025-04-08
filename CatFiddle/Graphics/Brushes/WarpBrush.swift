//
//  WarpBrush.swift
//  Brush
//
//  Created by Moon Davé on 12/11/20.
//

import MetalKit

struct WarpBrush: ReadImageBrush {

    var renderPipelineState: MTLRenderPipelineState
    var renderPassDescriptor: MTLRenderPassDescriptor
    var clearStrokePostRender: Bool = false


    let swapTexture: MTLTexture

    // TODO: this should only be updating its own vertices instead of redefining this.
    // OR the vertices in the Brush protocol extension can incorporate the aspect ratio
    private var vertices: [Vertex] {
        // this is literally gross and shouldn't go into main
        let ratio = Renderer.aspect
        return [
            // Triangle A
            Vertex(position: [-ratio, 1, 0], uv: [0, 0]), // top left
            Vertex(position: [-ratio, -1, 0], uv: [0, 1]), // bottom left
            Vertex(position: [ratio, -1, 0], uv: [1, 1]), // bottom right

            // Triangle B
            Vertex(position: [-ratio, 1, 0], uv: [0, 0]), // top left
            Vertex(position: [ratio, -1, 0], uv: [1, 1]), // bottom right
            Vertex(position: [ratio, 1, 0], uv: [1, 0]), // top right
        ]
    }

    init() {
        self.swapTexture = Renderer.makeTexture(
            size: Renderer.drawableSize,
            pixelFormat: .bgra8Unorm,
            usage: [.shaderRead, .renderTarget]
        )

        self.renderPassDescriptor = MTLRenderPassDescriptor()
        let attachment: MTLRenderPassColorAttachmentDescriptor = self.renderPassDescriptor.colorAttachments[0]
        attachment.texture = self.swapTexture
        attachment.loadAction = .dontCare
        attachment.storeAction = .store
        attachment.clearColor = MTLClearColorMake(0.73, 0.92, 1, 1)

        self.renderPipelineState = Renderer.createPipelineState(
            label: "Warp Brush",
            vertexFunction: "defaultBrushVertex",
            fragmentFunction: "warpBrushFragment",
            pixelFormat: .bgra8Unorm
        )
    }

    func render(commandBuffer: MTLCommandBuffer, stroke: Stroke, readLayer: Layer, writeLayer: Layer, uniforms: Uniforms) {

        // Note: We're not using the write layer at all. Which is strange

        guard
            let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: self.renderPassDescriptor)
        else { fatalError("Could not create render command encoder") }

        let numVerts = self.vertices.count
        let center = stroke.last ?? Point(pos: [0.5, 0.5])

        renderCommandEncoder.setRenderPipelineState(self.renderPipelineState)

        var uniforms = uniforms
        let scale = matrix_float4x4(scaling: 10)
        uniforms.modelMatrix = scale
        renderCommandEncoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            index: Int(BufferIndexUniforms.rawValue)
        )
        renderCommandEncoder.setFragmentBytes(
            &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            index: Int(BufferIndexUniforms.rawValue)
        )

        renderCommandEncoder.setVertexBytes(
            self.vertices,
            length: MemoryLayout<Vertex>.stride * numVerts,
            index: Int(BufferIndexVertices.rawValue)
        )

        var pos = center.pos * [Renderer.aspect, 1]
        renderCommandEncoder.setFragmentBytes(
            &pos,
            length: MemoryLayout<SIMD2<Float>>.stride,
            index: Int(BufferIndexCenter.rawValue)
        )
        renderCommandEncoder.setFragmentTexture(readLayer.texture, index: Int(TextureIndexBackground.rawValue))

        renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVerts)
        renderCommandEncoder.endEncoding()

        self.swapTextures(commandBuffer: commandBuffer, from: self.swapTexture, to: readLayer.texture)

    }

    private func swapTextures(commandBuffer: MTLCommandBuffer, from: MTLTexture, to: MTLTexture) {
        guard let blitCommandBuffer = commandBuffer.makeBlitCommandEncoder() else { return }
        blitCommandBuffer.copy(from: from, to: to)
        blitCommandBuffer.endEncoding()
    }

}
