//
//  MultiSlider.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct MultiSliderView: View {
    
    @Binding var values: [Float]
    
    private var threshldButtonValues: [Float] {
        get {
            let v =  Array(values.dropFirst())
            return  Array(v.dropLast())
        }
        nonmutating set {
            values = [thresholdVeryLow] + newValue + [thresholdVeryHigh]
        }
    }
    var thresholdVeryHigh: Float {
        values.last ?? 200
    }
    var thresholdVeryLow: Float {
        values.first ?? 0
    }
    var colors: [Color] = [Color.aircastingGreen, Color.aircastingYellow, Color.aircastingOrange, Color.aircastingRed]
        
    var body: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.frame(in: .local).size.width
            
            ZStack {
                colors.last
                ForEach(threshldButtonValues.indices.reversed(), id: \.self) { index in
                    colors[index]
                        .frame(width: CGFloat(threshldButtonValues[index]) * frameWidth / CGFloat(thresholdVeryHigh))
                        .position(x: CGFloat(threshldButtonValues[index]) * frameWidth / CGFloat(thresholdVeryHigh) / 2,
                                  y:  geometry.frame(in: .local).size.height / 2)
                }
                
                ForEach(threshldButtonValues.indices, id: \.self) { index in
                    let value = threshldButtonValues[index]
                    
                    sliderButton
                        .position(x: CGFloat(value) * frameWidth / CGFloat(thresholdVeryHigh),
                                  y: geometry.frame(in: .local).size.height / 2)
                        .gesture(dragGesture(index: index, geometry: geometry))
                }
                labels(geometry: geometry)
            }
                .coordinateSpace(name: "MultiSliderSpace")
        }
        .frame(height: 5)
    }
    
    var sliderButton: some View {
            Color.white
                .frame(width: 15, height: 15)
                .clipShape(Circle())
                .shadow(color: Color(red: 156/255, green: 155/255, blue: 155/255, opacity: 0.5), radius: 9)
    }
    
    func dragGesture(index: Int, geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("MultiSliderSpace"))
            .onChanged { (dragValue) in
                let newX = dragValue.location.x
                var newValue = Float(newX * CGFloat(thresholdVeryHigh) / geometry.frame(in: .local).size.width)
                                
                let previousValue = index > 0 ? threshldButtonValues[index-1] : thresholdVeryLow
                let nextValue = index == threshldButtonValues.count-1 ? thresholdVeryHigh : threshldButtonValues[index+1]
                
                newValue = min(nextValue,  newValue)
                newValue = max(previousValue, newValue)

                threshldButtonValues.replaceSubrange(index...index, with: [Float(newValue)])
            }
    }
    
    func labels(geometry: GeometryProxy) -> some View {
        let frameWidth = geometry.frame(in: .local).size.width
        let y = geometry.frame(in: .local).size.height / 2
        return ForEach(values.indices, id: \.self) { index in
            let ints = Int(values[index])
            Text("\(ints)")
                .position(x: CGFloat(values[index]) * frameWidth / CGFloat(thresholdVeryHigh),
                          y: y)
                .foregroundColor(.aircastingGray)
                .font(Font.muli(size: 12))
                .offset(x: 0, y: 20)
        }
    }
}

struct MultiSlider_Previews: PreviewProvider {
    static var previews: some View {
        MultiSliderView(values: .constant([0,5,10,13,20]))
    }
}
