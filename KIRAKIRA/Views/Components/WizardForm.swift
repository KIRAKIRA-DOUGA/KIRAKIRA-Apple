//
//  WizardForm.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/12/15.
//

import SwiftUI

struct WizardForm<Content: View, Footer: View>: View {
    let systemImage: String
    let iconStyle: AnyShapeStyle?
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource?
    let content: Content
    let footer: Footer
    init(
        systemImage: String,
        iconStyle: AnyShapeStyle? = nil,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.systemImage = systemImage
        self.iconStyle = iconStyle
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.footer = footer()
    }

    private let horizontalPadding: CGFloat = 34
    private let verticalPadding: CGFloat = 36
    @State private var isVisible = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: verticalPadding) {
                    HStack {
                        Spacer()
                        Image(systemName: systemImage)
                            .font(.system(size: 64))
                            .imageScale(.large)
                            .frame(height: 72)
                            .foregroundStyle(iconStyle ?? AnyShapeStyle(.accent.gradient))
                            .symbolEffect(.drawOn, isActive: !isVisible)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    isVisible = true
                                }
                            }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                        if subtitle != nil {
                            Text(subtitle!)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            content
        }
        .listSectionSpacing(verticalPadding)
        .scrollContentBackground(.hidden)
        .safeAreaBar(edge: .bottom) {
            footer
                .controlSize(.large)
                .fontWeight(.semibold)
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .padding(.horizontal, horizontalPadding)
        }
    }
}
