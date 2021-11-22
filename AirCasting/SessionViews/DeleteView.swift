// Created by Lunar on 09/07/2021.
//

import AirCastingStyling
import SwiftUI

struct DeleteView<VM: DeleteSessionViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var deleteModal: Bool
    @State var showingAlert: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            title
            description
            chooseStream
            continueButton
            cancelButton
        }.alert(isPresented: $showingAlert) {
            Alert(
                title: Text(Strings.DeleteSession.deleteAlert),
                primaryButton: .destructive(Text(Strings.DeleteSession.deleteButton), action: {
                    viewModel.deleteSelected()
                    deleteModal.toggle()
                }),
                secondaryButton: .default(Text(Strings.DeleteSession.cancelButton), action: {
                    deleteModal.toggle()
                }))
        }
        .padding()
    }
    
    private var title: some View {
        Text(Strings.DeleteSession.title)
            .font(Fonts.boldTitle4)
            .foregroundColor(.darkBlue)
    }
    
    private var description: some View {
        Text(Strings.DeleteSession.description)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    private var chooseStream: some View {
        VStack(alignment: .leading) {
            ForEach(viewModel.options, id: \.id) { option in
                HStack {
                    CheckBox(isSelected: option.isSelected).onTapGesture {
                        viewModel.didSelect(option: option)
                    }
                    Text(option.title)
                }
            }
        }.padding()
    }
    
    private var continueButton: some View {
        Button {
            showingAlert = true
        } label: {
            Text(Strings.DeleteSession.continueButton)
                .bold()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button {
            deleteModal.toggle()
        } label: {
            Text(Strings.DeleteSession.cancelButton)
        }
        .buttonStyle(BlueTextButtonStyle())
    }
}

#if DEBUG
struct DeleteViewModal_Previews: PreviewProvider {
    static var previews: some View {
        DeleteView(viewModel: DefaultDeleteSessionViewModel(session: .mock,
                                                            measurementStreamStorage: PreviewMeasurementStreamStorage(),
                                                            streamRemover: StreamRemoverDefaultDummy()),
                                                            deleteModal: .constant(false))
    }
}
#endif
