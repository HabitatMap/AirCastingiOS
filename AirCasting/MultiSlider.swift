//
//  MultiSlider.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct MultiSlider: View {
    
    var maxValue: Float = 100
    var values: [Float] = [43, 56, 78]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(values, id: \.self) { value in
                    button
                        .position(x: CGFloat(value) * geometry.frame(in: .local).size.width / CGFloat(maxValue),
                                  y: geometry.frame(in: .local).size.height / 2)
                }
            }
        }
    }
    
    var button: some View {
        Color.red
            .frame(width: 30, height: 30)
            .clipShape(Circle())
    }
}

struct MultiSlider_Previews: PreviewProvider {
    static var previews: some View {
        MultiSlider()
    }
}
