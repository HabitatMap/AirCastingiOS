//
//  CreatingSessionFlowRootView.swift
//  AirCasting
//
//  Created by Lunar on 31/03/2021.
//

import SwiftUI

struct CreatingSessionFlowRootView<Content: View>: View {
    let content: () -> Content

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            content()
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: backButton)
        }
    }

    var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }, label: {
            HStack {
                Text("Cancel")
            }
        })
    }
}

struct CreatingSessionFlowRootView_Previews: PreviewProvider {
    static var previews: some View {
        CreatingSessionFlowRootView {
            Text("")
        }
    }
}
