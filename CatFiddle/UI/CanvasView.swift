//
//  CanvasView.swift
//  Brush
//
//  Created by Moon Davé on 10/29/20.
//

import SwiftUI
import MetalKit

class CanvasViewController: UIViewController {

    private var metalView: MTKView
    private var renderer: Renderer

    private var lastPoint: Point?
    private var lastTime: TimeInterval?

    // MARK: - Initializers

    init(sharedRenderer: SharedRenderer) {
        self.renderer = sharedRenderer.renderer
        self.metalView = sharedRenderer.renderer.metalView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        metalView.frame = self.view.frame
        self.view.addSubview(metalView)
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            let canvas = self.renderer.canvas,
            let touch = touches.first,
            touch.type == .pencil || touch.type == .direct
        else { return }

        canvas.startNewStroke()
        let point = touch.getPoint(in: self.view)
        canvas.currentStroke?.append(point)
        self.lastPoint = point
        self.lastTime = touch.timestamp
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            let canvas = self.renderer.canvas,
            let lastTime = self.lastTime,
            let lastPoint = self.lastPoint,
            let touch = touches.first,
            touch.type == .pencil || touch.type == .direct
        else { return }

        let currentTime = touch.timestamp
        let dist = Settings.brushSize * 0.01
        var point = touch.getPoint(in: self.view)

        guard distance(point.pos, lastPoint.pos) > dist else { return }

        point.vel = (point.pos - lastPoint.pos) / (Float(currentTime - lastTime)/1000)

        canvas.currentStroke?.append(point)

        // Fill in intermediate points based on `dist`
        let direction = normalize(point.pos - lastPoint.pos)*dist
        var pp = lastPoint.pos
        while (distance(pp, point.pos) > dist) {
            pp = pp + direction
            canvas.currentStroke?.append(Point(pos: pp, vel: point.vel, angle: point.angle, pressure: point.pressure))
        }

        self.lastPoint = point
        self.lastTime = currentTime
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            let canvas = self.renderer.canvas,
            let touch = touches.first,
            touch.type == .pencil || touch.type == .direct
        else { return }
        
        canvas.endStroke()
        self.lastPoint = nil
        self.lastTime = nil
    }

}

// MARK: - CanvasView

struct CanvasView: UIViewControllerRepresentable {
    @EnvironmentObject var sharedRenderer: SharedRenderer

    func makeUIViewController(context: Context) -> CanvasViewController {
        return CanvasViewController(sharedRenderer: self.sharedRenderer)
    }

    func updateUIViewController(_ uiViewController: CanvasViewController, context: Context) {}

    func makeUIView(context: Context) -> MTKView {
        let renderer = self.sharedRenderer.renderer
        let metalView = renderer.metalView
        // Do any additional metalView configuration here
        return metalView
    }

}
