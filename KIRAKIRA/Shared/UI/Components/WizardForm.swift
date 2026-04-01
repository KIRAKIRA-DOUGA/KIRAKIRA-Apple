import SwiftUI

struct WizardForm<Content: View, Footer: View>: View {
    @Environment(AppUIState.self) private var appUIState
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
                                .frame(height: 80)
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
                                .font(.system(size: 80, weight: .light))
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
                .listRowBackground(Color.clear)
        }
        .contentMargins(.top, 0)
        .listSectionSpacing(15)
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Color.clear.frame(width: 0, height: 0)  // Hide navigation bar title
            }
        }
        .safeAreaBar(edge: .bottom) {
            VStack(spacing: 10) {
                footer
                    .controlSize(.large)
                    .fontWeight(.semibold)
                    .buttonStyle(.glassProminent)
                    .buttonSizing(.flexible)
                    .frame(maxWidth: 360)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 38)
                    .padding(.bottom, appUIState.isShowingKeyboard ? 16 : 0)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WizardForm(
            systemImage: "testtube.2", title: "WizardForm Test", subtitle: "Apple's wizard layout, now reusable!"
        ) {
            WizardSection {
                Text(verbatim: "Some text")
            }
        } footer: {
            Button {

            } label: {
                Text(verbatim: "Action Button")
            }

            Button {

            } label: {
                Text(verbatim: "Secondary Action Button")
            }.buttonStyle(.glass)
        }
        .navigationTitle("WizardForm Test")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Menu", systemImage: "ellipsis", action: {})
            }
        }
    }
}
