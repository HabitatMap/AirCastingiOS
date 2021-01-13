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
    var colors: [Color] = [Color.chartGreen, Color.chartYellow, Color.chartOrange, Color.chartRed]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(values.indices.reversed(), id: \.self) { index in
                    colors[index]
                        .frame(width: CGFloat(values[index]) * geometry.frame(in: .local).size.width / CGFloat(maxValue))
                        .position(x: CGFloat(values[index]) * geometry.frame(in: .local).size.width / CGFloat(maxValue) / 2,
                                  y:  geometry.frame(in: .local).size.height / 2)
                }
                
                ForEach(values, id: \.self) { value in
                    button
                        .position(x: CGFloat(value) * geometry.frame(in: .local).size.width / CGFloat(maxValue),
                                  y: geometry.frame(in: .local).size.height / 2)
                }
            }
        }
        .frame(height: 10)
        .padding()
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
