// Created by Lunar on 09/07/2021.
//

import SwiftUI
import AirCastingStyling

struct DeleteView: View {
    @Binding var deleteModal: Bool
    @State private var allStreams = true
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
        Text(Strings.deleteSession.title)
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }
    
    private var description: some View {
        Text(Strings.deleteSession.description)
            .font(Font.muli(size: 16))
            .foregroundColor(.aircastingGray)
    }
    
    private var chooseStream: some View {
        VStack(alignment: .leading) {
            HStack {
                CheckBox(isSelected: allStreams)
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
            Text(Strings.deleteSession.continueButton)
                .bold()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button {
            deleteModal.toggle()
        } label: {
            Text(Strings.deleteSession.cancelButton)
        }
        .buttonStyle(BlueTextButtonStyle())
    }
}

#if DEBUG
struct DeleteViewModal_Previews: PreviewProvider {
    static var previews: some View {
        DeleteView(deleteModal: .constant(false))
    }
}
#endif
