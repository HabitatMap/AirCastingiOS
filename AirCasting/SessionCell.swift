//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import SwiftUI

struct SessionCell: View {
    
    @State private var isCollapsed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            SessionHeader {
                withAnimation {
                    isCollapsed = !isCollapsed
                }
            }
            
            if !isCollapsed {
                VStack(alignment: .trailing, spacing: 40) {
                    pollutionChart
                    buttons
                }
            }
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Color.white
                .shadow(color: Color(red: 205/255, green: 209/255, blue: 214/255, opacity: 0.36), radius: 9, x: 0, y: 1)
        )
    }
    
    var pollutionChart: some View {
        PollutionChart()
            .frame(height: 200)
    }
    var graphButton: some View {
        Button("graph") {}
    }
    var mapButton: some View {
        Button("map") {}
    }
    var buttons: some View {
        HStack(spacing: 20){
            mapButton
            graphButton
        }
        .buttonStyle(GrayButtonStyle())
    }
}

struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        SessionCell()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
