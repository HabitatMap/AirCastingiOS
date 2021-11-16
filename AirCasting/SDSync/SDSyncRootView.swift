// Created by Lunar on 16/11/2021.
//

import SwiftUI

struct SDSyncRootView<Content: View>: View {
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

struct SDSyncRootView_Previews: PreviewProvider {
    static var previews: some View {
        SDSyncRootView {
            Text("")
        }
    }
}
