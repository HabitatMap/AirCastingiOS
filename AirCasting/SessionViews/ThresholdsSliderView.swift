//
//  MultiSlider.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI
import Resolver

struct ThresholdsSliderView: View {
    @Binding var thresholds: [Float]
    let threshold: SensorThreshold
    private let formatter: ThresholdFormatter
    
    init(threshold: SensorThreshold) {
        self.threshold = threshold
        self.formatter = Resolver.resolve(ThresholdFormatter.self, args: threshold)
        self._thresholds = .init(projectedValue: threshold.rawThresholdsBinding)
    }
    
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
            ZStack {
                colors.last
                ForEach(thresholdButtonValues.indices.reversed(), id: \.self) { index in
                    colors[index]
                        .frame(width: calculateXAxisSize(thresholdValue: thresholdButtonValues[index], geometry: geometry))
                        .position(x: calculateXAxisSize(thresholdValue: thresholdButtonValues[index], geometry: geometry) / 2,
                                  y:  geometry.frame(in: .local).size.height / 2)
                }
                
                ForEach(thresholdButtonValues.indices, id: \.self) { index in
                    sliderButton
                        .position(x: calculateXAxisSize(thresholdValue: thresholdButtonValues[index], geometry: geometry),
                                  y: geometry.frame(in: .local).size.height / 2)
                        .gesture(dragGesture(index: index, geometry: geometry))
                }
                labels(geometry: geometry)
            }
            .coordinateSpace(name: "MultiSliderSpace")
        }
        .frame(height: 5)
    }
    
    func calculateXAxisSize(thresholdValue: Float, geometry: GeometryProxy) -> CGFloat {
        let frameWidth = geometry.frame(in: .local).size.width
        return CGFloat(thresholdValue - thresholdVeryLow) / CGFloat(thresholdVeryHigh - thresholdVeryLow) * frameWidth
    }
    
    var sliderButton: some View {
            Color.white
                .frame(width: 18, height: 25)
                .clipShape(Circle())
                .shadow(color: Color(red: 156/255, green: 155/255, blue: 155/255, opacity: 0.5), radius: 9)
    }
    
    func dragGesture(index: Int, geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("MultiSliderSpace"))
            .onChanged { (dragValue) in
                let newX = dragValue.location.x
                let frameWidth = Float(geometry.frame(in: .local).size.width)
                var newValue = Float(newX) * (thresholdVeryHigh - thresholdVeryLow) / frameWidth + thresholdVeryLow
                let previousValue = index > 0 ? thresholdButtonValues[index-1] : thresholdVeryLow
                let nextValue = index == thresholdButtonValues.count-1 ? thresholdVeryHigh : thresholdButtonValues[index+1]
                
                newValue = min(nextValue,  newValue)
                newValue = max(previousValue, newValue)

                thresholdButtonValues.replaceSubrange(index...index, with: [Float(newValue)])
            }
    }
    
    func labels(geometry: GeometryProxy) -> some View {
        let y = geometry.frame(in: .local).size.height / 2
        return ForEach(thresholds.indices, id: \.self) { index in
            let ints = Int(formatter.formattedNumerics()[index])
            Text("\(ints)")
                .position(x: calculateXAxisSize(thresholdValue: thresholds[index], geometry: geometry),
                          y: y)
                .foregroundColor(.aircastingGray)
                .font(Fonts.muliHeading5)
                .offset(x: 0, y: 20)
        }
    }
}

#if DEBUG
struct MultiSlider_Previews: PreviewProvider {
    static var previews: some View {
        ThresholdsSliderView(threshold: .mock)
    }
}
#endif

