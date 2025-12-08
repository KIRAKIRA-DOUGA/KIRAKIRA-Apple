//
//  LabelStyle.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/11.
//

import SwiftUI

struct MonoColorLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .foregroundColor(Color(UIColor.label))
        }
    }
}
