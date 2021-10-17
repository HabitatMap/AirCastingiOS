// Created by Lunar on 08/07/2021.
//

import SwiftUI
import AirCastingStyling

struct EditViewModal: View {
    
    @Binding var showModalEdit: Bool
    @State private var sessionName = ""
    @State private var sessionTags = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            titleLabel
                .padding(.bottom, 20)
            createTextfield(placeholder: Strings.EditSession.namePlaceholder, binding: $sessionName)
            createTextfield(placeholder: Strings.EditSession.tagPlaceholder, binding: $sessionTags)
            Spacer()
            continueButton
            cancelButton
        }.padding()
    }
    
    var titleLabel: some View {
        Text(Strings.EditSession.title)
            .font(Fonts.EditModalView.title)
            .foregroundColor(.darkBlue)
    }
    
    private var continueButton: some View {
        Button(action: {
            showModalEdit.toggle()
        }, label: {
            Text(Strings.EditSession.buttonAccept)
                .font(Fonts.EditModalView.continueButton)
        }).buttonStyle(BlueButtonStyle())
        .padding(.top, 20)
    }
    
    private var cancelButton: some View {
        Button(Strings.BackendSettings.Cancel) {
            showModalEdit.toggle()
        }.buttonStyle(BlueTextButtonStyle())
    }
}
#if DEBUG
struct EditViewModal_Previews: PreviewProvider {
    static var previews: some View {
        EditViewModal(showModalEdit: .constant(false))
    }
}
#endif
