// Created by Lunar on 09/07/2021.
//

import SwiftUI
import AirCastingStyling

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
        }.padding()
    }
    
    private var title: some View {
        Text(Strings.deleteSession.title)
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }
    
    private var description: some View {
        Text(Strings.deleteSession.description)
            .font(Font.muli(size: 16))
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
            Text(Strings.deleteSession.continueButton)
                .bold()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button {
            deleteModal.toggle()
        } label: {
            Text(Strings.deleteSession.cancelButton)
        }
        .buttonStyle(BlueTextButtonStyle())
    }
}

extension View {
    func Print(_ vars: Any...) -> some View {
        for v in vars { print(v) }
        return EmptyView()
    }
}

#if DEBUG
struct DeleteViewModal_Previews: PreviewProvider {
    static var previews: some View {
        DeleteView(viewModel: DefaultDeleteSessionViewModel(), deleteModal: .constant(false))
    }
}
#endif
