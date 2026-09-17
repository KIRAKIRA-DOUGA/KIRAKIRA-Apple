import SwiftUI
import UIKit

@MainActor
@Observable
final class LargeImageViewerContext {
    var loadedImage: UIImage?
    var didImageLoadFail = false
    var areControlsVisible = true
    private(set) var isDismissing = false

    private weak var controller: UIViewController?
    private weak var scrollView: UIScrollView?
    private weak var imageView: UIImageView?

    init(initialImage: UIImage? = nil) {
        loadedImage = initialImage
    }

    var isAtMinimumZoom: Bool {
        guard let scrollView else { return true }
        return scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01
    }

    func connect(controller: UIViewController) {
        self.controller = controller
    }

    func connect(scrollView: UIScrollView, imageView: UIImageView) {
        self.scrollView = scrollView
        self.imageView = imageView
    }

    func alignmentRect() -> CGRect? {
        guard let controller, let imageView, imageView.image != nil else { return nil }
        return imageView.convert(imageView.bounds, to: controller.view)
    }

    func dismiss() {
        guard !isDismissing, let controller else { return }
        isDismissing = true
        areControlsVisible = false

        guard let scrollView,
            scrollView.zoomScale > scrollView.minimumZoomScale + 0.01
        else {
            controller.dismiss(animated: true)
            return
        }

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
            scrollView.layoutIfNeeded()
        } completion: { _ in
            controller.dismiss(animated: true)
        }
    }
}

@MainActor
enum LargeImageViewerPresenter {
    static func present(
        imageURL: URL,
        title: String?,
        source: ZoomTransitionSource
    ) {
        guard let sourceView = source.imageView else { return }
        guard let presentingController = sourceView.nearestViewController
            ?? sourceView.window?.rootViewController?.topmostViewController
        else { return }

        let context = LargeImageViewerContext(initialImage: sourceView.image)
        let viewer = LargeImageViewerView(
            imageURL: imageURL,
            title: title,
            context: context
        )
        let controller = UIHostingController(rootView: viewer)
        controller.modalPresentationStyle = .fullScreen
        controller.view.backgroundColor = .black
        controller.overrideUserInterfaceStyle = .dark
        context.connect(controller: controller)

        let options = UIViewController.Transition.ZoomOptions()
        options.dimmingColor = .black
        options.alignmentRectProvider = { [weak context] _ in
            context?.alignmentRect()
        }
        options.interactiveDismissShouldBegin = { [weak context] _ in
            context?.isAtMinimumZoom ?? true
        }
        controller.preferredTransition = .zoom(options: options) { [weak source] _ in
            source?.imageView
        }

        presentingController.present(controller, animated: true)
    }
}

private extension UIView {
    var nearestViewController: UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }
}

private extension UIViewController {
    var topmostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topmostViewController
        }
        if let navigationController = self as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController
        {
            return visibleViewController.topmostViewController
        }
        if let tabBarController = self as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController
        {
            return selectedViewController.topmostViewController
        }
        return self
    }
}
