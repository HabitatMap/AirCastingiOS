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
        NavigationView {
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
    }
    
    var continueButton: some View {
        NavigationLink(destination: ConfirmCreatingSessionView()) {
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

func createTextfield(placeholder: String, binding: Binding<String> ) -> some View {
  TextField(placeholder,
       text: binding)
    .padding()
    .frame(height: 50)
    .background(Color.aircastingGray.opacity(0.05))
    .border(Color.aircastingGray.opacity(0.1))
}

