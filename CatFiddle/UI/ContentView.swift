//
//  ContentView.swift
//  Brush
//
//  Created by Moon Davé on 10/29/20.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var sharedRenderer: SharedRenderer

    @State private var brushSize: Float = 0.5

    private var strokeColorBinding = Binding<Color>(
        get: { return Settings.color },
        set: { color in Settings.color = color }
    )

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CanvasView()
                    .environmentObject(self.sharedRenderer)
                HStack {
                    VStack {
                        BrushSelector()
                        DynamicSelector()
                        Slider(value: self.$brushSize, in: 0.1...1.0, onEditingChanged: { editing in
                            Settings.brushSize = self.brushSize
                        })
                        Text("Brush Size: \(self.brushSize)")
                        ColorPicker("Color", selection: self.strokeColorBinding)
                    }
                    .frame(width: 250, height: geo.size.height)
                    .background(Color.pink)
                    Spacer()
                }


            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
