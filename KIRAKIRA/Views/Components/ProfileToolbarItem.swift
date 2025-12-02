import SwiftUI

struct ProfileToolbarItem: ToolbarContent {
    @Environment(GlobalStateManager.self) private var globalStateManager

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { globalStateManager.mainTabSelection = .me }) {
                Image("SamplePortrait")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .sharedBackgroundVisibility(.hidden)
    }
}
