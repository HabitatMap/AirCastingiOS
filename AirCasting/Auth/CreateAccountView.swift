//
//  CreateAccountView.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import SwiftUI

struct CreateAccountView: View {
    
    @State private var username: String = ""
    @State private var password: String = ""

    
    var body: some View {
        VStack(spacing: 50) {
            titleLabel
            VStack(spacing: 20) {
                usernameTextfield
                passwordTextfield
                confirmPasswordTextfield
            }
        }
        .padding()
    }
    
    var titleLabel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Create account")
                .font(Font.moderate(size: 32,
                                    weight: .bold))
                .foregroundColor(.accentColor)
            Text("to record and map your envitonment")
                .font(Font.muli(size: 16))
                .foregroundColor(.aircastingGray)
        }
    }
    
    var usernameTextfield: some View {
        createTextfield(placeholder: "Username",
                        binding: $username)
    }
    var passwordTextfield: some View {
        createTextfield(placeholder: "Password",
                        binding: $password)
    }
    var confirmPasswordTextfield: some View {
        createTextfield(placeholder: "Repeat password",
                        binding: $password)
    }

//    var signinButton: some View {
//
//    }
    
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
