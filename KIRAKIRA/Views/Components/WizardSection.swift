//
//  WizardSection.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/12/15.
//

import SwiftUI

struct WizardSection<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    private let horizontalPadding: CGFloat = 34

    
    var body: some View {
        Section {
            content()
        }
        .listSectionMargins(.horizontal, horizontalPadding)
        .listRowBackground(Color(UIColor.secondarySystemBackground))
    }
}

#Preview {
    WizardSection() {
        Text("测试")
    }
}
