// Created by Lunar on 01/07/2022.
//

import SwiftUI

func createNoteTextField(binding: Binding<String>) -> some View {
    Log.info("## binding: \(binding)")
    return TextView(text: binding, placeholder: Strings.Commons.note)
              .frame(minWidth: UIScreen.main.bounds.width - 30,
                     maxWidth: UIScreen.main.bounds.width - 30,
                     minHeight: (UIScreen.main.bounds.height) / 3 < 200 ? (UIScreen.main.bounds.height / 3) : 200,
                     maxHeight: 200,
                     alignment: .topLeading)
      }
