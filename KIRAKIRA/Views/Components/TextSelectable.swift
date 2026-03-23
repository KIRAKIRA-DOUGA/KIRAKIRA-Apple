import SwiftUI
import SwiftUIIntrospect

struct TextSelectable: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        TextField(text, text: .constant(text), axis: .vertical)
            .lineHeight(.normal)
            .textFieldStyle(.plain)
            .introspect(.textField(axis: .vertical), on: .iOS(.v26)) { textField in
                textField.clipsToBounds = false
                textField.isEditable = false
                textField.isScrollEnabled = false
            }
    }
}
