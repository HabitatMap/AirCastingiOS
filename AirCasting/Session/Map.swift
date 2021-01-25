//
//  Map.swift
//  AirCasting
//
//  Created by Lunar on 25/01/2021.
//

import SwiftUI

struct Map: View {
    var body: some View {
        VStack {
            SessionHeader(action: {}, isExpandButtonNeeded: false)
//            MultiSlider(values: Binding<[Float]>)
        }
    }
}

struct Map_Previews: PreviewProvider {
    static var previews: some View {
        Map()
    }
}
