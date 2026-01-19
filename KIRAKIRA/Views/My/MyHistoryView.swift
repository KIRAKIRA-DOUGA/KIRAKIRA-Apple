import SwiftUI

struct MyHistoryView: View {
    var body: some View {
        ScrollView {
            ForEach(1...10, id: \.self) { _ in
                // VideoListItemView()
                EmptyView()
            }
        }
        .navigationTitle(.userHistory)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    MyHistoryView()
}
