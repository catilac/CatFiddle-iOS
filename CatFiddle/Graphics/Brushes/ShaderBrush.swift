//
//  Shader.swift
//  Brush
//
//  Created by Moon Davé on 12/1/20.
//

import MetalKit

struct ShaderBrush: BasicBrush {

    var renderPipelineState: MTLRenderPipelineState
    var clearStrokePostRender: Bool = true

    init() {
        self.renderPipelineState = Renderer.createPipelineState(
            label: "Shader Brush",
            vertexFunction: "defaultBrushVertex",
            fragmentFunction: "shaderBrushFragment",
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

        renderEncoder.setVertexBytes(
            self.vertices,
            length: MemoryLayout<Vertex>.stride * numVerts,
            index: Int(BufferIndexVertices.rawValue)
        )

        var color = Settings.color.toSIMD()
        renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD3<Float>>.stride, index: Int(BufferIndexColor.rawValue))

        for p in stroke {

            let translate = float4x4(translation: SIMD3<Float>(10 * p.pos.x * Renderer.aspect, 10 * p.pos.y, 0))
            uniforms.modelMatrix = translate * float4x4(scaling: Settings.brushSize)
            uniforms.pressure = p.pressure
            uniforms.velocity = p.vel
            uniforms.angle = p.angle
            
            renderEncoder.setVertexBytes(
                &uniforms,
                length: MemoryLayout<Uniforms>.stride,
                index: Int(BufferIndexUniforms.rawValue)
            )

            renderEncoder.setFragmentBytes(
                &uniforms,
                length: MemoryLayout<Uniforms>.stride,
                index: Int(BufferIndexUniforms.rawValue)
            )

            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVerts)
        }

        renderEncoder.endEncoding()
    }

}
