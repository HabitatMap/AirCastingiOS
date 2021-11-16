// Created by Lunar on 16/11/2021.
//

import SwiftUI

struct SDSyncRootView: View {
    @Environment(\.presentationMode) var presentationMode
    let viewModel = SDSyncViewModel()

    var body: some View {
        NavigationView {
            Text("Syncing")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: backButton)
        }
        .onAppear(perform: viewModel.startSync)
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
        SDSyncRootView()
    }
}
