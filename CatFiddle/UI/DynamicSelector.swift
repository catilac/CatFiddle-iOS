//
//  DynamicSelector.swift
//  CatFiddle
//
//  Created by Moon Davé on 12/30/20.
//

import SwiftUI

enum DynamicType: String, CaseIterable, Identifiable, Equatable {
    case time, pressure, angle, velocity

    var dynamic: Dynamic {
        switch self {
        case .time:
            return DynamicTime
        case .pressure:
            return DynamicPressure
        case .angle:
            return DynamicAngle
        case .velocity:
            return DynamicVelocity
        }
    }

    var id: String { self.rawValue }
}

struct DynamicSelector: View {

    @State var currentDynamic: DynamicType = .time

    var body: some View {
        VStack(alignment: .center) {
            Picker("DYNAMIC", selection: self.$currentDynamic) {
                ForEach(DynamicType.allCases) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }.pickerStyle(SegmentedPickerStyle())
        }.onChange(of: self.currentDynamic) { dynamicType in
            Settings.currentDynamic = dynamicType.dynamic
        }
    }
}

struct DynamicSelector_Previews: PreviewProvider {
    static var previews: some View {
        DynamicSelector()
    }
}
