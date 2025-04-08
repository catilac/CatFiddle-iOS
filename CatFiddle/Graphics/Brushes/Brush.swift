//
//  Brush.swift
//  Brush
//
//  Created by Moon Davé on 11/6/20.
//

import MetalKit

protocol Brush {

    var renderPipelineState: MTLRenderPipelineState { get }
    var clearStrokePostRender: Bool { get }

}

/// `BasicBrush` is a standard brush. Takes some stroke information and does what is necessary to render it to a layer
protocol BasicBrush: Brush {

    func render(commandBuffer: MTLCommandBuffer, stroke: Stroke, layer: Layer, uniforms: Uniforms)

}

/// `ReadImageBrush` is a brush that utilizes an input image in order to determine what gets rendered
protocol ReadImageBrush: Brush {

    func render(commandBuffer: MTLCommandBuffer, stroke: Stroke, readLayer: Layer, writeLayer: Layer, uniforms: Uniforms)

}

extension Brush {

    // TODO: Perhaps this could be generalized into a buffer or something? It can be shared...
    var vertices: [Vertex] {
        return [
            // Triangle A
            Vertex(position: [-1,  1, 0], uv: [0, 0]),
            Vertex(position: [-1, -1, 0], uv: [0, 1]),
            Vertex(position: [ 1, -1, 0], uv: [1, 1]),
            
            // Triangle B
            Vertex(position: [-1,  1, 0], uv: [0, 0]),
            Vertex(position: [ 1, -1, 0], uv: [1, 1]),
            Vertex(position: [ 1,  1, 0], uv: [1, 0]),
        ]
    }

}
