//
//  CreateSessionView.swift
//  AirCasting
//
//  Created by Lunar on 05/02/2021.
//

import SwiftUI

struct ChooseSessionTypeView: View {
    var body: some View {
        VStack(spacing: 50) {
            VStack(alignment: .leading, spacing: 10) {
                titleLabel
                messageLabel
            }
            .background(Color.white)
            .padding(.horizontal)
            
            VStack {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        recordNewLabel
                        Spacer()
                        moreInfo
                    }
                    HStack(spacing: 60) {
                        fixedSessionButton
                        mobileSessionButton
                    }
                }
                Spacer()
            }
            .padding()
            .background(
                Color.aircastingBackground.opacity(0.25)
                    .ignoresSafeArea()
            )
        }
        
    }
    var titleLabel: some View {
        Text("Let's begin")
            .font(Font.moderate(size: 32,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    var messageLabel: some View {
        Text("How would you like to add your session?")
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
    }
    
    var recordNewLabel: some View {
        Text("Record a new session")
            .font(Font.muli(size: 14, weight: .bold))
            .foregroundColor(.aircastingDarkGray)
    }
    
    var moreInfo: some View {
        Button(action: {
            print("you'll find out soon enough")
        }, label: {
            Text("more info")
                .font(Font.moderate(size: 14))
                .foregroundColor(.accentColor)
        })
    }
    
    var fixedSessionButton: some View {
        NavigationLink(destination: TurnOnBluetoothView()) {
            fixedSessionLabel
        }
    }
    
    var mobileSessionButton: some View {
        NavigationLink(destination: SelectDeviceView()) {
            mobileSessionLabel
        }
    }
    
    var fixedSessionLabel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fixed session")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("for measuring in one place")
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
        .padding()
        .frame(maxWidth: 145, maxHeight: 145)
        .background(Color.white)
        .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
    }
    
    var mobileSessionLabel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mobile session")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("for moving around")
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
        .padding()
        .frame(maxWidth: 145, maxHeight: 145)
        .background(Color.white)
        .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
    }
}

struct CreateSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseSessionTypeView()
    }
}
