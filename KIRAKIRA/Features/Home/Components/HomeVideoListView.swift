import SwiftUI

struct HomeVideoListView: View {
    let videos: [ThumbVideoItem]
    @Binding var isPlayerExpanded: Bool
    let animationNamespace: Namespace.ID

    var body: some View {
        VideoListView(
            videos: videos,
            isPlayerExpanded: $isPlayerExpanded,
            animationNamespace: animationNamespace,
        ) {
            HomeTabPickerView()
        }
    }
}

struct HomeTabPickerView: View {
    @Environment(HomeBrowseState.self) private var homeBrowseState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories, id: \.id) { category in
                    Button {
                        withAnimation {
                            homeBrowseState.selectedCategory = category
                        }
                    } label: {
                        Label {
                            if homeBrowseState.selectedCategory == category {
                                Text(category.name)
                                    .fontWeight(.medium)
                            }
                        } icon: {
                            Image(systemName: category.systemImage)
                        }
                        .labelIconToTitleSpacing(4)
                        .frame(minWidth: 24)
                    }
                    .tint(homeBrowseState.selectedCategory == category ? .accent : .secondary)
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
