// Created by Lunar on 09/07/2021.
//

import AirCastingStyling
import SwiftUI

struct DeleteView<VM: DeleteSessionViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var deleteModal: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            title
            description
            chooseStream
            continueButton
            cancelButton
        }.onAppear(perform: {
            #warning("When implementing logic here we will differ what type of session it is")
//            sessionContext.sessionType == .mobile ? viewModel.isMicrophoneToggle() : viewModel.isNotMicrophoneToggle()
        })
        .padding()
    }
    
    private var title: some View {
        Text(Strings.DeleteSession.title)
            .font(Fonts.DeleteView.title)
            .foregroundColor(.darkBlue)
    }
    
    private var description: some View {
        Text(Strings.DeleteSession.description)
            .font(Fonts.DeleteView.description)
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
            deleteModal.toggle()
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
        DeleteView(viewModel: DefaultDeleteSessionViewModel(), deleteModal: .constant(false))
    }
}
#endif
