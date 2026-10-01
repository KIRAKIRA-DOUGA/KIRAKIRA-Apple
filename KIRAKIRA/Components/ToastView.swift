import SwiftUI

struct ToastView: View {
    @Bindable var manager: ToastManager

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            if let toast = manager.toast {
                HStack(spacing: 8) {
                    if let systemImage = toast.systemImage {
                        Image(systemName: systemImage)
                    }

                    Text(toast.message)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(toast.tint == nil ? Color.primary : Color.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .glassEffect(.regular.tint(toast.tint), in: .capsule)
                .padding(.horizontal)
                .safeAreaPadding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: manager.toast?.id)
        .allowsHitTesting(false)
        .accessibilityHidden(manager.toast == nil)
    }
}

#Preview {
    ToastView(manager: .shared)
        .task {
            ToastManager.shared.show(
                String(localized: .actionDone),
                style: .success
            )
        }
}
