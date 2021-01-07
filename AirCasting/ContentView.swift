//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI

extension Font {
    static func muli(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("Muli", fixedSize: size).weight(weight)
    }
    static func moderate(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("Moderat-Trial-Regular", fixedSize: size).weight(weight)
    }
}

extension Color {
    static var aircastingGray: Color {
        return Color("AircastingGray700")
    }
    static var darkBlue: Color {
        return Color("DarkBlue")
    }
}

struct ContentView: View {
    
    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    Picker(selection: /*@START_MENU_TOKEN@*/.constant(1)/*@END_MENU_TOKEN@*/, label: /*@START_MENU_TOKEN@*/Text("Picker")/*@END_MENU_TOKEN@*/, content: {
                        Text("Following").tag(1)
                        Text("Active").tag(2)
                        Text("Dormant").tag(3)
                        Text("Fixed").tag(4)
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    emptyState
                }
            }
            .tabItem { Text("+") }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 45) {
            Spacer()
            VStack(spacing: 14) {
                
                Text("Ready to get started?")
                    .font(Font.moderate(size: 24, weight: .bold))
                    .foregroundColor(Color.darkBlue)
                
                Text("Explore & follow existing AirCasting sessions or use your own device to record a new session and monitor your health & environment.")
                    .font(Font.muli(size: 16))
                    .foregroundColor(Color.aircastingGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(9.0)
                    .padding(.horizontal, 45)
            }
            VStack(spacing: 20) {
                Button(action: {}, label: {
                    Text("Record new session")
                        .bold()
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 40)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                        .padding(-3)
                        .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
                })
                Button(action: {}, label: {
                    Text("Explore existing sessions")
                        .foregroundColor(.accentColor)
                })
            }
            Spacer()
        }
        .padding()
        .navigationBarTitle("Dashboard")
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
