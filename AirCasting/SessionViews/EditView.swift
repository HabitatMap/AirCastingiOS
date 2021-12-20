// Created by Lunar on 08/07/2021.
//

import SwiftUI
import AirCastingStyling

struct EditView: View {
    
    @State private var isSessionDownloaded = false
    private let measurementStreamStorage: MeasurementStreamStorage
    let sessionUUID: SessionUUID
    private let sessionSynchronizer: SessionSynchronizer
    let sessionUpdateService: SessionUpdateService
    @Binding var showModalEdit: Bool
    @StateObject private var editSessionViewModel: EditSessionViewModel

    
    init(measurementStreamStorage: MeasurementStreamStorage, sessionUUID: SessionUUID, sessionSynchronizer: SessionSynchronizer, sessionUpdateService: SessionUpdateService, showModalEdit: Binding<Bool>) {
        self.measurementStreamStorage = measurementStreamStorage
        self.sessionUUID = sessionUUID
        self.sessionSynchronizer = sessionSynchronizer
        self.sessionUpdateService = sessionUpdateService
        _showModalEdit = showModalEdit
        _editSessionViewModel = .init(wrappedValue: EditSessionViewModel(measurementStreamStorage: measurementStreamStorage,
                                                                         sessionUpdateService: sessionUpdateService))
    }
    
    var body: some View {
        ZStack {
            if isSessionDownloaded {
                editView
            } else {
                loader
            }
        }
        .onAppear {
            sessionSynchronizer.downloadSingleSession(sessionUUID: sessionUUID) {
                isSessionDownloaded = true
                editSessionViewModel.reloadWith(sessionUUID)
            }
        }
    }
    
    var editView: some View {
        VStack(alignment: .leading) {
            Spacer()
            titleLabel
                .padding(.bottom, 20)
            createTextfield(placeholder: Strings.EditSession.namePlaceholder,
                            binding: $editSessionViewModel.sessionName)
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
            editSessionViewModel.saveChanges(for: sessionUUID) {
                showModalEdit.toggle()
            }
        }, label: {
            Text(Strings.EditSession.buttonAccept)
                .font(Fonts.semiboldHeading1)
        }).buttonStyle(BlueButtonStyle())
        .padding(.top, 20)
    }
    
    private var cancelButton: some View {
        Button(Strings.BackendSettings.Cancel) {
            showModalEdit.toggle()
        }.buttonStyle(BlueTextButtonStyle())
    }
}
#if DEBUG
struct EditViewModal_Previews: PreviewProvider {
    static var previews: some View {
        EditView(measurementStreamStorage: PreviewMeasurementStreamStorage(),
                 sessionUUID: SessionEntity.mock.uuid,
                 sessionSynchronizer: DummySessionSynchronizer(),
                 sessionUpdateService: SessionUpdateServiceDefaultDummy(),
                 showModalEdit: .constant(false))
    }
}
#endif
