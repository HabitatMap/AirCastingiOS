// Created by Lunar on 09/07/2021.
//

import AirCastingStyling
import SwiftUI

struct DeleteView<VM: DeleteSessionViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var deleteModal: Bool
    
    var body: some View {
        ZStack {
            XMarkButton()
            VStack(alignment: .leading, spacing: 20) {
                title
                description
                chooseStream
                continueButton
                cancelButton
            }
            .alert(isPresented: $viewModel.showingConfirmationAlert) {
                Alert(
                    title: Text(Strings.DeleteSession.deleteAlert),
                    primaryButton: .destructive(Text(Strings.DeleteSession.deleteButton), action: {
                        viewModel.deleteSelected()
                        deleteModal.toggle()
                    }),
                    secondaryButton: .default(Text(Strings.Commons.cancel), action: {
                        deleteModal.toggle()
                    }))
            }
            .padding()
        }
    }
    
    private var title: some View {
        Text(Strings.DeleteSession.title)
            .font(Fonts.muliHeavyTitle1)
            .foregroundColor(.darkBlue)
    }
    
    private var description: some View {
        Text(Strings.DeleteSession.description)
            .font(Fonts.moderateRegularHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    private var chooseStream: some View {
        VStack(alignment: .leading) {
            ForEach(viewModel.streamOptions, id: \.id) { option in
                HStack {
                    CheckBox(isSelected: option.isSelected).onTapGesture {
                        viewModel.didSelect(option: option)
                    }
                    Text(option.title)
                        .font(Fonts.muliBoldHeading1)
                }
            }
        }.padding()
    }
    
    private var continueButton: some View {
        Button {
            viewModel.showConfirmationAlert()
        } label: {
            Text(Strings.DeleteSession.continueButton)
                .font(Fonts.muliBoldHeading1)
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button {
            deleteModal.toggle()
        } label: {
            Text(Strings.Commons.cancel)
        }
        .buttonStyle(BlueTextButtonStyle())
    }
}
