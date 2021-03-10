//
//  AddNameAndTagsView.swift
//  AirCasting
//
//  Created by Anna Olak on 24/02/2021.
//

import SwiftUI

struct AddNameAndTagsView: View {
    @State var sessionName = ""
    @State var sessionTags = ""
    
    var body: some View {
            VStack(alignment: .leading, spacing: 50) {
                ProgressView(value: 0.75)
                titleLabel
                createTextfield(placeholder: "Session name", binding: $sessionName)
                createTextfield(placeholder: "Tags", binding: $sessionTags)
                Spacer()
                continueButton
                    .buttonStyle(BlueButtonStyle())
            }
            .padding()
            
    }
    
    var continueButton: some View {
        NavigationLink(destination: ConfirmCreatingSessionView(sessionType: "Mobile", sessionName: sessionName)) {
            Text("Continue")
                .frame(maxWidth: .infinity)
        }
    }
    
    var titleLabel: some View {
        Text("New session details")
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }
}

struct AddNameAndTagsView_Previews: PreviewProvider {
    static var previews: some View {
        AddNameAndTagsView()
    }
}
