// Created by Lunar on 08/07/2021.
//

import SwiftUI
import AirCastingStyling

struct EditView<VM: EditViewModel>: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var editSessionViewModel: VM

    init(viewModel: VM) {
        _editSessionViewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            XMarkButton()
            if editSessionViewModel.isSessionDownloaded {
                editView
            } else {
                loader
            }
        }
        .background(Color.aircastingBackgroundWhite.ignoresSafeArea())
        .onAppear {
            editSessionViewModel.viewAppeared()
        }
        .onChange(of: editSessionViewModel.shouldDismiss) {
            $0 ? presentationMode.wrappedValue.dismiss() : ()
        }
        .alert(item: $editSessionViewModel.alert, content: { $0.makeAlert() })
    }
    
    var editView: some View {
        VStack(alignment: .leading) {
            Spacer()
            titleLabel
                .padding(.bottom, 20)
            VStack(alignment: .leading) {
                createLabel(with: Strings.EditSession.sessionNameLabel)
                createTextfield(placeholder: Strings.EditSession.sessionNamePlaceholder,
                                binding: $editSessionViewModel.sessionName)
                .font(Fonts.moderateRegularHeading2)
                if editSessionViewModel.shouldShowError {
                    errorMessage(text: Strings.EditSession.erorr)
                }
            }
            .padding(.bottom)
            Group {
                createLabel(with: Strings.EditSession.sessionTagsLabel)
                createTextfield(placeholder: Strings.EditSession.tagPlaceholder,
                                binding: $editSessionViewModel.sessionTags)
                .font(Fonts.moderateRegularHeading2)
            }
            Spacer()
            saveButton
            cancelButton
        }
        .padding()
    }
    
    var loader: some View {
        VStack(alignment: .center) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
        }
    }
    
    var titleLabel: some View {
        Text(Strings.EditSession.title)
            .font(Fonts.muliHeavyTitle1)
            .foregroundColor(.darkBlue)
    }
    
    private var saveButton: some View {
        Button(action: {
            editSessionViewModel.saveChanges()
        }, label: {
            Text(Strings.EditSession.buttonAccept)
                .font(Fonts.muliBoldHeading1)
        })
            .buttonStyle(BlueButtonStyle())
            .padding(.top, 20)
    }
    
    private var cancelButton: some View {
        Button(Strings.Commons.cancel) {
            presentationMode.wrappedValue.dismiss()
        }.buttonStyle(BlueTextButtonStyle())
    }
    
    private func createLabel(with text: String) -> some View {
        Text(text)
            .font(Fonts.muliBoldHeading2)
            .foregroundColor(.aircastingDarkGray)
    }
}
