import SwiftUI

struct ProfileToolbarItem: ToolbarContent {
    @Environment(AppRouter.self) private var appRouter
    @Environment(AuthManager.self) private var authManager

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { appRouter.mainTabSelection = .me }) {
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
