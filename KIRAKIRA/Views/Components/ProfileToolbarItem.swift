import SwiftUI

struct ProfileToolbarItem: ToolbarContent {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var authManager = AuthManager.shared

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { globalStateManager.mainTabSelection = .me }) {
                if authManager.isAuthenticated {
                    Image("SamplePortrait")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.accent)
                }
            }
            .buttonStyle(.plain)
        }
        .sharedBackgroundVisibility(.hidden)
    }
}
