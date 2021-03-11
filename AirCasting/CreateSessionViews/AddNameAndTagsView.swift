//
//  AddNameAndTagsView.swift
//  AirCasting
//
//  Created by Anna Olak on 24/02/2021.
//

import SwiftUI

struct AddNameAndTagsView: View {
    @State var sessionName: String = ""
    @State var sessionTags: String = ""
    @State private var isConfirmCreatingSessionActive: Bool = false
    @EnvironmentObject private var sessionContext: CreateSessionContext

    var body: some View {
        VStack(alignment: .leading, spacing: 50) {
            ProgressView(value: 0.75)
            titleLabel
            createTextfield(placeholder: "Session name", binding: $sessionName)
            createTextfield(placeholder: "Tags", binding: $sessionTags)
            Spacer()
            continueButton
        }
        .padding()
        
    }
    
    var continueButton: some View {
        Button(action: {
            sessionContext.sessionName = sessionName
            sessionContext.sessionTags = sessionTags
            isConfirmCreatingSessionActive = true
        }, label: {
            Text("Continue")
                .frame(maxWidth: .infinity)
        })
        .buttonStyle(BlueButtonStyle())
        .background( Group {
            NavigationLink(
                destination: ConfirmCreatingSessionView(sessionName: sessionName),
                isActive: $isConfirmCreatingSessionActive,
                label: {
                    EmptyView()
                })
        })
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
