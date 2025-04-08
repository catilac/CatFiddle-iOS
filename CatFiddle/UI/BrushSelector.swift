//
//  BrushSelector.swift
//  Brush
//
//  Created by Moon Davé on 12/5/20.
//

import SwiftUI

enum BrushType: String, CaseIterable, Identifiable, Equatable {
    case basic, shader, blob, pixel, warp

    var brush: Brush {
        switch self {
        case .basic:
            return DefaultBrush()
        case .shader:
            return ShaderBrush()
        case .blob:
            return BlobBrush()
        case .pixel:
            return PixelixerBrush()
        case .warp:
            return WarpBrush()
        }
    }

    var id: String { self.rawValue }

}

struct BrushSelector: View {

    @State var currentBrush: BrushType = .basic

    var body: some View {
        VStack(alignment: .center) {
            Picker("BRUSH", selection: self.$currentBrush) {
                ForEach(BrushType.allCases) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }.pickerStyle(SegmentedPickerStyle())
        }.onChange(of: self.currentBrush) { brushType in
            Settings.currentBrush = brushType.brush
        }
    }


}

struct BrushSelector_Previews: PreviewProvider {
    static var previews: some View {
        BrushSelector()
    }
}
