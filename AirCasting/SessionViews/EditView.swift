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
            if editSessionViewModel.isSessionDownloaded {
                editView
            } else {
                loader
            }
        }
        .onAppear {
            editSessionViewModel.downloadSessionAndReloadView()
        }
    }
    
    var editView: some View {
        VStack(alignment: .leading) {
            Spacer()
            titleLabel
                .padding(.bottom, 20)
            createTextfield(placeholder: Strings.EditSession.namePlaceholder,
                            binding: $editSessionViewModel.sessionName)
            if editSessionViewModel.shouldShowError {
                errorMessage(text: Strings.EditSession.erorr)
            }
            createTextfield(placeholder: Strings.EditSession.tagPlaceholder,
                            binding: $editSessionViewModel.sessionTags)
            Spacer()
            saveButton
            cancelButton
        }.padding()
    }
    
    var loader: some View {
        VStack(alignment: .center) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
        }
    }
    
    var titleLabel: some View {
        Text(Strings.EditSession.title)
            .font(Fonts.boldTitle4)
            .foregroundColor(.darkBlue)
    }
    
    private var saveButton: some View {
        Button(action: {
            editSessionViewModel.saveChanges()
        }, label: {
            Text(Strings.EditSession.buttonAccept)
                .font(Fonts.semiboldHeading1)
        })
            .buttonStyle(BlueButtonStyle())
            .padding(.top, 20)
            .onChange(of: editSessionViewModel.didSave) {
                $0 ? presentationMode.wrappedValue.dismiss() : ()
            }
    }
    
    private var cancelButton: some View {
        Button(Strings.BackendSettings.Cancel) {
            presentationMode.wrappedValue.dismiss()
        }.buttonStyle(BlueTextButtonStyle())
    }
}

#if DEBUG
struct EditViewModal_Previews: PreviewProvider {
    static var previews: some View {
        let vm = EditSessionViewModel(measurementStreamStorage: PreviewMeasurementStreamStorage(),
                                      sessionSynchronizer: DummySessionSynchronizer(),
                                      sessionUpdateService: SessionUpdateServiceDefaultDummy(),
                                      sessionUUID: SessionEntity.mock.uuid)
        return EditView(viewModel: vm)
    }
}
#endif