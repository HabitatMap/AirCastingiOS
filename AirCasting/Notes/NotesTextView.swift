// Created by Lunar on 20/01/2022.

import SwiftUI

func createNoteTextField(binding: Binding<String>) -> some View {
    TextView(text: binding, placeholder: Strings.Commons.note)
        .frame(minWidth: UIScreen.main.bounds.width - 30,
               maxWidth: UIScreen.main.bounds.width - 30,
               minHeight: (UIScreen.main.bounds.height) / 3 < 200 ? (UIScreen.main.bounds.height / 3) : 200,
               maxHeight: 200,
               alignment: .topLeading)
}

func createEditNoteTextField(binding: Binding<String>) -> some View {
    TextView(text: binding, placeholder: Strings.Commons.note, noteIsEditing: true)
        .frame(minWidth: UIScreen.main.bounds.width - 30,
               maxWidth: UIScreen.main.bounds.width - 30,
               minHeight: (UIScreen.main.bounds.height) / 3 < 200 ? (UIScreen.main.bounds.height / 3) : 200,
               maxHeight: 200,
               alignment: .topLeading)
}
