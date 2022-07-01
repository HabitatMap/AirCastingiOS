// Created by Lunar on 01/07/2022.
//

import SwiftUI

func createNoteTextField(binding: Binding<String>, isEditing: Bool = false) -> some View {
    TextView(text: binding, placeholder: Strings.Commons.note, isEditing: isEditing)
              .frame(minWidth: UIScreen.main.bounds.width - 30,
                     maxWidth: UIScreen.main.bounds.width - 30,
                     minHeight: (UIScreen.main.bounds.height) / 3 < 200 ? (UIScreen.main.bounds.height / 3) : 200,
                     maxHeight: 200,
                     alignment: .topLeading)
      }
