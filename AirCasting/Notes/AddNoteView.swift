// Created by Lunar on 16/12/2021.
//

import SwiftUI
import AirCastingStyling

struct AddNoteView: View {
    @State private var xx = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            title
            description
            noteField
            continueButton
            cancelButton
        }.padding()
    }
}

private extension AddNoteView {
    
    var title: some View {
        Text("Add a note")
            .font(Fonts.boldTitle4)
            .foregroundColor(.darkBlue)
    }
    
    var description: some View {
        Text("Your note will be timestamped and displayed on the AirCasting map")
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    var noteField: some View {
        TextField("NOTE", text: $xx)
            .padding()
            .frame(minWidth: UIScreen.main.bounds.width - 40,
                   maxWidth: UIScreen.main.bounds.width - 40,
                   minHeight: (UIScreen.main.bounds.height) / 3 < 200 ? (UIScreen.main.bounds.height / 3) : 200,
                   maxHeight: 200,
                   alignment: .topLeading)
            .background(Color.aircastingGray.opacity(0.05))
            .border(Color.aircastingGray.opacity(0.1))
    }
    var continueButton: some View {
        Button {
           //)
        } label: {
            Text("Add a note")
                .bold()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var cancelButton: some View {
        Button {
           //
        } label: {
            Text("Cancel")
        }
        .buttonStyle(BlueTextButtonStyle())
    }
}

struct AddNoteView_Previews: PreviewProvider {
    static var previews: some View {
        AddNoteView()
    }
}
