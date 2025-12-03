import SwiftUI

struct HomeVideoListView: View {
    let videos: [VideoListItemDTO]
    let animationNamespace: Namespace.ID

    var body: some View {
        VideoListView(
            videos: videos,
            animationNamespace: animationNamespace
        ) {
            HomeTabPickerView()
        }
    }
}

struct HomeTabPickerView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories, id: \.id) { category in
                    Button {
                        withAnimation {
                            globalStateManager.selectedCategory = category
                        }
                    } label: {
                        Label {
                            if globalStateManager.selectedCategory == category {
                                Text(category.name)
                                    .fontWeight(.medium)
                            }
                        } icon: {
                            Image(systemName: category.systemImage)
                        }
                        .frame(minWidth: 24)
                    }
                    .tint(globalStateManager.selectedCategory == category ? .accent : .secondary)
                    .buttonStyle(.bordered)
                    .clipShape(Capsule())
                }
            }
        }
        .scrollClipDisabled()
    }
}

#Preview(traits: .commonPreviewTrait) {
    HomeTabPickerView()
}
