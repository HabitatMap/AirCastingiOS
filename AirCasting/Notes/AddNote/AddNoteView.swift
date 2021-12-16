// Created by Lunar on 16/12/2021.
//
import SwiftUI
import AirCastingStyling

struct AddNoteView<VM: AddNoteViewModel>: View {
    @StateObject var viewModel: VM
    @Binding var addNoteModal: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            title
            description
            noteField
            continueButton
            cancelButton
        }.padding()
    }
}

private extension AddNoteView {
    
    var title: some View {
        Text(Strings.AddNoteView.title)
            .font(Fonts.boldTitle4)
            .foregroundColor(.darkBlue)
    }
    
    var description: some View {
        Text(Strings.AddNoteView.description)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    var noteField: some View {
        TextField(Strings.AddNoteView.placeholder, text: $viewModel.noteText)
            .padding()
            .frame(minWidth: UIScreen.main.bounds.width - 40,
                   maxWidth: UIScreen.main.bounds.width - 40,
                   minHeight: (UIScreen.main.bounds.height) / 3 < 200 ? (UIScreen.main.bounds.height / 3) : 200,
                   maxHeight: 200,
                   alignment: .topLeading)
            .background(Color.aircastingGray.opacity(0.05))
            .border(Color.aircastingGray.opacity(0.1))
    }
    
    var continueButton: some View {
        Button {
            //
        } label: {
            Text(Strings.AddNoteView.continueButton)
                .bold()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var cancelButton: some View {
        Button {
            addNoteModal.toggle()
        } label: {
            Text(Strings.AddNoteView.cancelButton)
        }
        .buttonStyle(BlueTextButtonStyle())
    }
}

#if DEBUG
struct AddNoteView_Previews: PreviewProvider {
    static var previews: some View {
        AddNoteView(viewModel: DummyAddNoteViewModelDefault(), addNoteModal: .constant(true))
    }
}
#endif
