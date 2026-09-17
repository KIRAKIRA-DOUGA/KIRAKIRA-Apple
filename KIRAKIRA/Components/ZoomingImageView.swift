import Kingfisher
import SwiftUI
import UIKit

struct ZoomingImageView: UIViewRepresentable {
    let imageURL: URL
    let context: LargeImageViewerContext

    func makeCoordinator() -> Coordinator {
        Coordinator(context: context)
    }

    func makeUIView(context: Context) -> ZoomingScrollView {
        let scrollView = ZoomingScrollView()
        let imageView = context.coordinator.imageView

        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .clear
        scrollView.layoutHandler = { [weak coordinator = context.coordinator] in
            coordinator?.layoutImage()
        }
        context.coordinator.connect(scrollView: scrollView)

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSingleTap)
        )
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)

        self.context.connect(scrollView: scrollView, imageView: imageView)
        context.coordinator.load(imageURL)
        return scrollView
    }

    func updateUIView(_ scrollView: ZoomingScrollView, context: Context) {
        self.context.connect(scrollView: scrollView, imageView: context.coordinator.imageView)
        context.coordinator.load(imageURL)
    }

    static func dismantleUIView(_ scrollView: ZoomingScrollView, coordinator: Coordinator) {
        coordinator.imageView.kf.cancelDownloadTask()
    }

    @MainActor
    final class Coordinator: NSObject, UIScrollViewDelegate {
        let imageView = UIImageView()

        private let context: LargeImageViewerContext
        private weak var scrollView: UIScrollView?
        private var imageURL: URL?
        private var lastLayoutSize = CGSize.zero

        init(context: LargeImageViewerContext) {
            self.context = context
            super.init()
            imageView.image = context.loadedImage
        }

        func connect(scrollView: UIScrollView) {
            self.scrollView = scrollView
        }

        func load(_ url: URL) {
            guard imageURL != url else {
                layoutImage()
                return
            }
            imageURL = url

            imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))]) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let value):
                    context.loadedImage = value.image
                    context.didImageLoadFail = false
                    layoutImage(resetZoom: true)
                case .failure:
                    context.didImageLoadFail = true
                }
            }
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            self.scrollView = scrollView
            return imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            self.scrollView = scrollView
            centerImage(in: scrollView)
        }

        func layoutImage(resetZoom: Bool = false) {
            guard let scrollView = imageView.superview as? UIScrollView,
                let image = imageView.image,
                scrollView.bounds.width > 0,
                scrollView.bounds.height > 0
            else { return }

            self.scrollView = scrollView
            let boundsSize = scrollView.bounds.size
            guard resetZoom || boundsSize != lastLayoutSize else { return }
            lastLayoutSize = boundsSize

            let widthScale = boundsSize.width / image.size.width
            let heightScale = boundsSize.height / image.size.height
            let fitScale = min(widthScale, heightScale)
            let fittedSize = CGSize(
                width: image.size.width * fitScale,
                height: image.size.height * fitScale
            )

            if resetZoom {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
            }
            imageView.frame = CGRect(origin: .zero, size: fittedSize)
            scrollView.contentSize = fittedSize
            centerImage(in: scrollView)
        }

        @objc func handleSingleTap() {
            context.areControlsVisible.toggle()
        }

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scrollView else { return }
            if scrollView.zoomScale > scrollView.minimumZoomScale + 0.01 {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
                return
            }

            let targetScale = min(2.5, scrollView.maximumZoomScale)
            let location = recognizer.location(in: imageView)
            let zoomSize = CGSize(
                width: scrollView.bounds.width / targetScale,
                height: scrollView.bounds.height / targetScale
            )
            let zoomRect = CGRect(
                x: location.x - zoomSize.width / 2,
                y: location.y - zoomSize.height / 2,
                width: zoomSize.width,
                height: zoomSize.height
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }

        private func centerImage(in scrollView: UIScrollView) {
            let horizontalInset = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
            let verticalInset = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
            scrollView.contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        }
    }
}

final class ZoomingScrollView: UIScrollView {
    var layoutHandler: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutHandler?()
    }
}
