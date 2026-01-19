import SwiftUI

struct MonoColorLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .foregroundColor(Color(UIColor.label))
        }
    }
}
