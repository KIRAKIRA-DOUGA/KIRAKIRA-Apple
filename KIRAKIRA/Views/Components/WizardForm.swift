//
//  WizardForm.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/12/15.
//

import SwiftUI

struct WizardForm<Content: View, Footer: View>: View {
    let systemImage: String?
    let image: String?
    let iconStyle: AnyShapeStyle?
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource?
    let content: Content
    let footer: Footer
    init(
        systemImage: String? = nil,
        image: String? = nil,
        iconStyle: AnyShapeStyle? = nil,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.systemImage = systemImage
        self.image = image
        self.iconStyle = iconStyle
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.footer = footer()
    }

    private let horizontalPadding: CGFloat = 34
    private let verticalPadding: CGFloat = 36
    @State private var isAnimationPlayed = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: verticalPadding) {
                    HStack {
                        Spacer()
                        if let image {
                            Image(image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 72)
                                .foregroundStyle(iconStyle ?? AnyShapeStyle(.accent.gradient))
                                .symbolEffect(.drawOn, isActive: !isAnimationPlayed)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        isAnimationPlayed = true
                                    }
                                }
                        }
                        if let systemImage {
                            Image(systemName: systemImage)
                                .font(.system(size: 60, weight: .light))
                                .imageScale(.large)
                                .frame(height: 72)
                                .foregroundStyle(iconStyle ?? AnyShapeStyle(.accent.gradient))
                                .symbolEffect(.drawOn, isActive: !isAnimationPlayed)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        isAnimationPlayed = true
                                    }
                                }
                        }
                        Spacer()
                    }
                    .frame(height: 86)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                        if let subtitle {
                            Text(subtitle)
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
        .contentMargins(.top, 0)
        .listSectionSpacing(15)
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
