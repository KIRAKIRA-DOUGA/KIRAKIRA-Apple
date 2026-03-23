import SwiftUI
import SwiftUIIntrospect

struct TextSelectable: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        TextField(text, text: .constant(text), axis: .vertical)
            .textFieldStyle(.plain)
            .introspect(.textField(axis: .vertical), on: .iOS(.v26)) { textField in
                textField.clipsToBounds = false
                textField.isEditable = false
                textField.isScrollEnabled = false
            }
    }
}

#Preview {
    @Previewable @State var opacity: CGFloat = 0.0

    let lorem =
        "**Lorem ipsum dolor sit amet**, consectetur adipiscing elit. *Sed sagittis metus vel mi viverra tincidunt.* Cras vitae ex efficitur, luctus eros in, porttitor lorem. Nunc auctor tincidunt massa, et luctus lacus ultricies eget. Nulla felis turpis, dignissim sit amet efficitur non, tincidunt convallis enim. Mauris mollis tincidunt urna, sed eleifend erat rutrum id. Etiam libero quam, feugiat nec placerat a, mattis at ligula. Nunc pellentesque ultricies mauris vel volutpat. Sed faucibus volutpat est vitae dignissim. Quisque consectetur pretium risus non elementum. Suspendisse et ornare sem. Nullam ut metus faucibus, congue ante sed, fringilla tortor. Ut vel ipsum porta, dignissim nulla ac, ullamcorper lectus. Nunc turpis turpis, placerat rhoncus vestibulum vel, tristique porttitor nibh. Pellentesque aliquam dignissim auctor."

    ScrollView {
        ZStack(alignment: .top) {
            TextSelectable(lorem)
            Text(lorem)
                .opacity(opacity)
        }
        .padding(.horizontal)
    }
    .safeAreaBar(edge: .bottom) {
        VStack(alignment: .leading) {
            Text(verbatim: "SwiftUI Text Opacity:")
            Slider(value: $opacity, in: 0...1)
        }
        .padding(.horizontal)
    }
}
