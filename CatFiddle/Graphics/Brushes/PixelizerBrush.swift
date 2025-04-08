//
//  PixelizerBrush.swift
//  Brush
//
//  Created by Moon Davé on 12/17/20.
//

import MetalKit

struct PixelixerBrush: ReadImageBrush {

    var renderPipelineState: MTLRenderPipelineState
    var clearStrokePostRender: Bool = true

    init() {
        self.renderPipelineState = Renderer.createPipelineState(
            label: "Pixelizer Brush",
            vertexFunction: "defaultBrushVertex",
            fragmentFunction: "pixelizerFragment",
            pixelFormat: .bgra8Unorm
        )
    }

    func render(commandBuffer: MTLCommandBuffer, stroke: Stroke, readLayer: Layer, writeLayer: Layer, uniforms: Uniforms) {
        guard
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: writeLayer.renderPassDescriptor)
        else {
            fatalError("Could not create render command encoder for Pixelizer")
        }

        let numVerts = self.vertices.count

        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        renderEncoder.setFragmentTexture(readLayer.texture, index: Int(TextureIndexBackground.rawValue))
        renderEncoder.setVertexBytes(
            self.vertices,
            length: MemoryLayout<Vertex>.stride * numVerts,
            index:Int(BufferIndexVertices.rawValue)
        )

        for p in stroke {
            var uniforms = uniforms
            let translate = float4x4(translation: SIMD3<Float>(10 * p.pos.x * Renderer.aspect, 10 * p.pos.y, 0))
            uniforms.modelMatrix = translate * float4x4(scaling: Settings.brushSize)
            renderEncoder.setVertexBytes(
                &uniforms,
                length: MemoryLayout<Uniforms>.stride,
                index: Int(BufferIndexUniforms.rawValue)
            )

            renderEncoder.setFragmentBytes(&Settings.brushSize, length: MemoryLayout<Float>.stride, index: Int(BufferIndexBrushSize.rawValue))

            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVerts)
        }

        renderEncoder.endEncoding()
    }




    
}
