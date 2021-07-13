// Created by Lunar on 09/07/2021.
//

import SwiftUI
import AirCastingStyling

struct DeleteViewModal: View {
    @Binding var deleteModal: Bool
    @State private var allMeasurements = true
    @State private var PM1 = false
    @State private var PM25 = false
    @State private var RH = false
    @State private var F = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            title
            description
            chooseStream
            continueButton
            cancelButton
        }.padding()
    }
    
    private var title: some View {
        Text("Delete this session")
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }
    
    private var description: some View {
        Text("Which stream would you like to delete?")
            .font(Font.muli(size: 16))
            .foregroundColor(.aircastingGray)
    }
    
    private var chooseStream: some View {
        VStack(alignment: .leading) {
            HStack {
                CheckBox(isSelected: allMeasurements)
                Text("All from the session")
            }
            HStack {
                CheckBox(isSelected: PM1)
                Text("PM1")
            }
            HStack {
                CheckBox(isSelected: PM25)
                Text("PM2.5")
            }
            HStack {
                CheckBox(isSelected: RH)
                Text("RH")
            }
            HStack {
                CheckBox(isSelected: F)
                Text("F")
            }
        }.padding()
    }
    
    private var continueButton: some View {
        Button {
            deleteModal.toggle()
        } label: {
            Text("Delete streams")
                .bold()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button {
            deleteModal.toggle()
        } label: {
            Text("Cancel")
        }
        .buttonStyle(BlueTextButtonStyle())
    }
}

struct DeleteViewModal_Previews: PreviewProvider {
    static var previews: some View {
        DeleteViewModal(deleteModal: .constant(false))
    }
}
