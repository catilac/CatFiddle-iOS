//
//  Layer.swift
//  Brush
//
//  Created by Moon Davé on 11/25/20.
//

import Metal

struct Layer {

    var texture: MTLTexture // The texture that the stroke gets rendered to
    var renderPassDescriptor: MTLRenderPassDescriptor // Descriptor for rendering output to texture

    init(size: MTLSize) {
        self.texture = Renderer.makeTexture(size: size, pixelFormat: .bgra8Unorm, usage: [.shaderRead, .renderTarget])
        self.renderPassDescriptor = MTLRenderPassDescriptor()
        let attachment: MTLRenderPassColorAttachmentDescriptor = self.renderPassDescriptor.colorAttachments[0]
        attachment.texture = self.texture
        attachment.loadAction = .load
        attachment.storeAction = .store
        attachment.clearColor = MTLClearColorMake(0.73, 0.92, 1, 1)
        
    }
}
