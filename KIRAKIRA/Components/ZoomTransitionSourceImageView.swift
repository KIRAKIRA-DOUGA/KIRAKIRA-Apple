import Kingfisher
import SwiftUI
import UIKit

@MainActor
final class ZoomTransitionSource {
    weak var imageView: UIImageView?
}

struct ZoomTransitionSourceImageView: UIViewRepresentable {
    let imageURL: URL?
    let source: ZoomTransitionSource
    let onTap: () -> Void

    func makeUIView(context: Context) -> ZoomTransitionSourceContainerView {
        let containerView = ZoomTransitionSourceContainerView()
        containerView.clipsToBounds = true
        containerView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap)
            )
        )
        let imageView = containerView.imageView
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .secondaryLabel
        source.imageView = imageView
        loadImage(in: imageView, coordinator: context.coordinator)
        return containerView
    }

    func updateUIView(_ containerView: ZoomTransitionSourceContainerView, context: Context) {
        let imageView = containerView.imageView
        context.coordinator.onTap = onTap
        source.imageView = imageView
        loadImage(in: imageView, coordinator: context.coordinator)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: ZoomTransitionSourceContainerView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width, let height = proposal.height else { return nil }
        return CGSize(width: width, height: height)
    }

    static func dismantleUIView(
        _ containerView: ZoomTransitionSourceContainerView,
        coordinator: Coordinator
    ) {
        containerView.imageView.kf.cancelDownloadTask()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    private func loadImage(in imageView: UIImageView, coordinator: Coordinator) {
        guard coordinator.imageURL != imageURL else { return }
        coordinator.imageURL = imageURL

        let placeholder = UIImage(systemName: "person.crop.circle.fill")
        imageView.kf.setImage(
            with: imageURL,
            placeholder: placeholder,
            options: [.transition(.fade(0.25))]
        )
    }

    final class Coordinator: NSObject {
        var imageURL: URL?
        var onTap: () -> Void

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        @objc func handleTap() {
            onTap()
        }
    }
}

final class ZoomTransitionSourceContainerView: UIView {
    let imageView = CircularSourceImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}

final class CircularSourceImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
}
