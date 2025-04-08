//
//  Blob.swift
//  Brush
//
//  Created by Moon Davé on 12/1/20.
//

import MetalKit

struct BlobBrush: BasicBrush {

    var renderPipelineState: MTLRenderPipelineState
    var clearStrokePostRender: Bool = false

    // MARK: Tessellation
    var tessellationPipelineState: MTLComputePipelineState
    var patchCount: Int = 1
    let edgeFactors: [Float] = [16]
    let insideFactors: [Float] = [16]
    let tessellationFactorsBuffer: MTLBuffer?


    var controlPointsBuffer: MTLBuffer?

    init() {
        guard
            let device = Renderer.device,
            let library = Renderer.library
        else { fatalError("Renderer not initialized") }

        let count = patchCount * (4 + 2)
        let size = count * MemoryLayout<Float>.size / 2
        self.tessellationFactorsBuffer = Renderer.device!.makeBuffer(length: size, options: .storageModePrivate)


        //
        // I wanted this render pipeline state creation code to go into a method,
        // but I'm going to leave it for now. It's already pretty much DRY.
        // Moreover, tesselation may not really be necessary for what we're trying to accomplish
        //
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride


        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "blob brush"

        pipelineStateDescriptor.vertexDescriptor = vertexDescriptor
        pipelineStateDescriptor.tessellationFactorStepFunction = .perPatch

        pipelineStateDescriptor.vertexFunction = library.makeFunction(name: "blobBrushVertex")
        pipelineStateDescriptor.fragmentFunction = library.makeFunction(name: "blobBrushFragment")
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        guard let attachment = pipelineStateDescriptor.colorAttachments[0] else { fatalError("No color attachment") }
        attachment.isBlendingEnabled = true
        attachment.alphaBlendOperation = .add
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            fatalError("Blob Brush: Could not create MTLRenderPipelineState")
        }

        guard
            let kernelFunction = library.makeFunction(name: "tessellation_main")
        else { fatalError("Could not make kernel function")}
        do {
            self.tessellationPipelineState = try device.makeComputePipelineState(function: kernelFunction)
        } catch {
            fatalError("Blob Brush: Could not create MTLComputePipelineState")
        }

        let controlPoints = self.createControlPoints()
        self.controlPointsBuffer = Renderer.device!.makeBuffer(
            bytes: controlPoints,
            length: MemoryLayout<SIMD2<Float>>.stride * controlPoints.count
        )
    }

    func render(commandBuffer: MTLCommandBuffer, stroke: [Point], layer: Layer, uniforms: Uniforms) {
        var uniforms = uniforms

        self.performTessellation(commandBuffer: commandBuffer)

        guard
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: layer.renderPassDescriptor)
        else { fatalError("Could not create layerRenderEncoder") }

        renderEncoder.setRenderPipelineState(self.renderPipelineState)

        renderEncoder.setTessellationFactorBuffer(self.tessellationFactorsBuffer, offset: 0, instanceStride: 0)
        renderEncoder.setVertexBuffer(self.controlPointsBuffer, offset: 0, index: 0)

        var dynamic = Settings.currentDynamic.rawValue
        renderEncoder.setFragmentBytes(&dynamic, length: MemoryLayout<UInt32>.stride, index: Int(BufferIndexDynamic.rawValue))

        for p in stroke {
            let translate = float4x4(translation: 10 * SIMD3<Float>(p.pos.x * Renderer.aspect, p.pos.y, 0))
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

            renderEncoder.drawPatches(
                numberOfPatchControlPoints: 16,
                patchStart: 0,
                patchCount: self.patchCount,
                patchIndexBuffer: nil,
                patchIndexBufferOffset: 0,
                instanceCount: 1,
                baseInstance: 0
            )
        }

        renderEncoder.endEncoding()
    }

    private func performTessellation(commandBuffer: MTLCommandBuffer) {
        guard
            let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else { fatalError("Coule not create compute encoder") }

        computeEncoder.setComputePipelineState(self.tessellationPipelineState)

        computeEncoder.setBytes(
            self.edgeFactors,
            length: MemoryLayout<Float>.size * self.edgeFactors.count,
            index: Int(BufferIndexEdgeFactors.rawValue)
        )
        computeEncoder.setBytes(
            self.insideFactors,
            length: MemoryLayout<Float>.size * self.edgeFactors.count,
            index: Int(BufferIndexInsideFactors.rawValue)
        )
        computeEncoder.setBuffer(
            self.tessellationFactorsBuffer,
            offset: 0,
            index: Int(BufferIndexTessellationFactors.rawValue)
        )

        let width = min(self.patchCount, self.tessellationPipelineState.threadExecutionWidth)
        computeEncoder.dispatchThreadgroups(MTLSizeMake(self.patchCount, 1, 1),
                                            threadsPerThreadgroup: MTLSizeMake(width, 1, 1))
        computeEncoder.endEncoding()


    }

    private func createControlPoints() -> [SIMD2<Float>] {
        var points: [SIMD2<Float>] = []

        // Figure out how to get correct aspect ratio, or pass it in to the shader
        // QUESTION: Can we scale this point inside of the MVP matrix somewhere?
        for i in 0..<4 {
            for j in 0..<4 {
                points.append([sin(radians(fromDegrees: Float(i) * 90)) * Renderer.aspect + 0.25,
                               cos(radians(fromDegrees: Float(j) * 90))])
            }
        }
//        for i in 0..<16 {
//            let rads = radians(fromDegrees: Float(i) * 22.5)
//            points.append([
//                sin(rads) * Renderer.aspect - (1/4),
//                cos(rads) / Renderer.aspect + (1/4)]
//            )
//        }
        return points
    }

}
