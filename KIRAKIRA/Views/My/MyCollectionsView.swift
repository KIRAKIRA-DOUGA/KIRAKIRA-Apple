//
//  MyCollectionsView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/14.
//

import SwiftUI

struct MyCollectionsView: View {
    var body: some View {
        ScrollView {
            ForEach(1...10, id: \.self) { _ in
                // VideoListItemView()
                EmptyView()
            }
        }
        .navigationTitle(.userFavorited)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    MyCollectionsView()
}
