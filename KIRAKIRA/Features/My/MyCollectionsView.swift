import SwiftUI

struct MyCollectionsView: View {
    var body: some View {
        ScrollView {
            ForEach(1...10, id: \.self) { _ in
                // VideoListItemView()
                EmptyView()
            }
        }
        .navigationTitle(.userCollections)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    MyCollectionsView()
}
