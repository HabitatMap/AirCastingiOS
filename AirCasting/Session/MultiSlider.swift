//
//  MultiSlider.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct MultiSlider: View {
    
    @Binding var values: [Float]
    
    private var buttonValues: [Float] {
        get {
            let v =  Array(values.dropFirst())
            return  Array(v.dropLast())
        }
        nonmutating set {
            values = [minValue] + newValue + [maxValue]
        }
    }
    var maxValue: Float {
        values.last ?? 200
    }
    var minValue: Float {
        values.first ?? 0
    }
    var colors: [Color] = [Color.chartGreen, Color.chartYellow, Color.chartOrange, Color.chartRed]
        
    var body: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.frame(in: .local).size.width
            
            ZStack {
                colors.last
                ForEach(buttonValues.indices.reversed(), id: \.self) { index in
                    colors[index]
                        .frame(width: CGFloat(buttonValues[index]) * frameWidth / CGFloat(maxValue))
                        .position(x: CGFloat(buttonValues[index]) * frameWidth / CGFloat(maxValue) / 2,
                                  y:  geometry.frame(in: .local).size.height / 2)
                }
                
                ForEach(buttonValues.indices, id: \.self) { index in
                    let value = buttonValues[index]
                    
                    sliderButton
                        .position(x: CGFloat(value) * frameWidth / CGFloat(maxValue),
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
                var newValue = Float(newX * CGFloat(maxValue) / geometry.frame(in: .local).size.width)
                                
                let previousValue = index > 0 ? buttonValues[index-1] : minValue
                let nextValue = index == buttonValues.count-1 ? maxValue : buttonValues[index+1]
                
                newValue = min(nextValue,  newValue)
                newValue = max(previousValue, newValue)

                buttonValues.replaceSubrange(index...index, with: [Float(newValue)])
            }
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
        MultiSlider(values: .constant([0,1,2,3]))
    }
}
