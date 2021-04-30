//
//  MultiSlider.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct ThresholdsSliderView: View {
    
    @ObservedObject var threshold: SensorThreshold
    
    var rawThresholdsBinding: Binding<[Float]> {
        Binding<[Float]> {
            [
                Float(threshold.thresholdVeryLow),
                Float(threshold.thresholdLow),
                Float(threshold.thresholdMedium),
                Float(threshold.thresholdHigh),
                Float(threshold.thresholdVeryHigh)
            ]
        } set: { newThresholds in
            guard newThresholds.count >= 5 else { return }
            threshold.thresholdVeryLow = Int32(newThresholds[0])
            threshold.thresholdLow = Int32(newThresholds[1])
            threshold.thresholdMedium = Int32(newThresholds[2])
            threshold.thresholdHigh = Int32(newThresholds[3])
            threshold.thresholdVeryHigh = Int32(newThresholds[4])
        }
    }
    
    var body: some View {
        MultiSliderView(thresholds: rawThresholdsBinding)
    }
}

struct MultiSliderView: View {
    
    @Binding var thresholds: [Float]
    
    private var thresholdButtonValues: [Float] {
        get {
            let v =  Array(thresholds.dropFirst())
            return  Array(v.dropLast())
        }
        nonmutating set {
            thresholds = [thresholdVeryLow] + newValue + [thresholdVeryHigh]
        }
    }
    var thresholdVeryHigh: Float {
        thresholds.last ?? 200
    }
    var thresholdVeryLow: Float {
        thresholds.first ?? 0
    }
    
    var colors: [Color] = [Color.aircastingGreen, Color.aircastingYellow, Color.aircastingOrange, Color.aircastingRed]
        
    var body: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.frame(in: .local).size.width
            
            ZStack {
                colors.last
                ForEach(thresholdButtonValues.indices.reversed(), id: \.self) { index in
                    colors[index]
                        .frame(width: CGFloat(thresholdButtonValues[index]) * frameWidth / CGFloat(thresholdVeryHigh))
                        .position(x: CGFloat(thresholdButtonValues[index]) * frameWidth / CGFloat(thresholdVeryHigh) / 2,
                                  y:  geometry.frame(in: .local).size.height / 2)
                }
                
                ForEach(thresholdButtonValues.indices, id: \.self) { index in
                    let value = thresholdButtonValues[index]
                    
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
                                
                let previousValue = index > 0 ? thresholdButtonValues[index-1] : thresholdVeryLow
                let nextValue = index == thresholdButtonValues.count-1 ? thresholdVeryHigh : thresholdButtonValues[index+1]
                
                newValue = min(nextValue,  newValue)
                newValue = max(previousValue, newValue)

                thresholdButtonValues.replaceSubrange(index...index, with: [Float(newValue)])
            }
    }
    
    func labels(geometry: GeometryProxy) -> some View {
        let frameWidth = geometry.frame(in: .local).size.width
        let y = geometry.frame(in: .local).size.height / 2
        return ForEach(thresholds.indices, id: \.self) { index in
            let ints = Int(thresholds[index])
            Text("\(ints)")
                .position(x: CGFloat(thresholds[index]) * frameWidth / CGFloat(thresholdVeryHigh),
                          y: y)
                .foregroundColor(.aircastingGray)
                .font(Font.muli(size: 12))
                .offset(x: 0, y: 20)
        }
    }
}

struct MultiSlider_Previews: PreviewProvider {
    static var previews: some View {
        ThresholdsSliderView(threshold: .mock)
    }
}


extension SensorThreshold {
    
    static var mock: SensorThreshold {
        let context = PersistenceController.shared.container.viewContext
        
        if let existing = try! context.existingObject(sensorName: "mock-threshold") {
            return existing
        }
        
        let threshold: SensorThreshold = try! context.newOrExisting(sensorName: "mock-threshold")

        threshold.thresholdVeryLow = 0
        threshold.thresholdLow = 10
        threshold.thresholdMedium = 20
        threshold.thresholdHigh = 30
        threshold.thresholdVeryHigh = 40
        
        return threshold
    }
    
}
