//
//  BrushApp.swift
//  Brush
//
//  Created by Moon Davé on 10/29/20.
//

import SwiftUI

// The Singleton for SwiftUI to pass around
class SharedRenderer: ObservableObject {
    @Published var renderer = Renderer()
}

@main
struct BrushApp: App {
    var sharedRenderer = SharedRenderer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .statusBar(hidden: true)
                .environmentObject(self.sharedRenderer)
        }
    }
}
