//
//  InfoItemView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/20.
//

import SwiftUI

struct InfoItemView: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
            Text(text).lineLimit(1)
        }
    }
}
