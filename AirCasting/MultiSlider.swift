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
            let frameWidth = geometry.frame(in: .local).size.width
            
            ZStack {
                colors.last
                
                ForEach(values.indices.reversed(), id: \.self) { index in
                    colors[index]
                        .frame(width: CGFloat(values[index]) * frameWidth / CGFloat(maxValue))
                        .position(x: CGFloat(values[index]) * frameWidth / CGFloat(maxValue) / 2,
                                  y:  geometry.frame(in: .local).size.height / 2)
                }
                
                ForEach(values, id: \.self) { value in
                    sliderButton
                        .position(x: CGFloat(value) * frameWidth / CGFloat(maxValue),
                                  y: geometry.frame(in: .local).size.height / 2)
                }
                labels(geometry: geometry)
            }

        }
        .frame(height: 5)
        .padding()
    }
    
    var sliderButton: some View {
            Color.white
                .frame(width: 15, height: 15)
                .clipShape(Circle())
                .shadow(color: Color(red: 156/255, green: 155/255, blue: 155/255, opacity: 0.5), radius: 9)
    }
    
    func labels(geometry: GeometryProxy) -> some View {
        let frameWidth = geometry.frame(in: .local).size.width
        let y = geometry.frame(in: .local).size.height / 2
        
        return ForEach(values.indices, id: \.self) { index in
            let ints = Int(values[index])
            Text("\(ints)")
                .position(x: CGFloat(values[index]) * frameWidth / CGFloat(maxValue),
                          y: y)
                .foregroundColor(.aircastingGray)
                .font(Font.muli(size: 12))
                .offset(x: 0, y: 20)
        }
    }
    
    
}

struct MultiSlider_Previews: PreviewProvider {
    static var previews: some View {
        MultiSlider()
    }
}
