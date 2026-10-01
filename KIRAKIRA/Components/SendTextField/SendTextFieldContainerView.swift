import UIKit

final class SendTextFieldContainerView: UIView {
    private let composerView: SendTextInputView
    private let cornerReferenceView = CornerReferenceView()
    var onCornerRadiusChange: (() -> Void)?

    var bottomCornerRadius: CGFloat { cornerReferenceView.bottomCornerRadius }

    var padding: CGFloat = 18 {
        didSet {
            guard padding != oldValue else { return }
            invalidateContentSize()
        }
    }

    init(composerView: SendTextInputView) {
        self.composerView = composerView
        super.init(frame: .zero)
        addSubview(cornerReferenceView)
        addSubview(composerView)
        composerView.onSizeChange = { [weak self] in
            self?.invalidateContentSize()
        }
        cornerReferenceView.onRadiusChange = { [weak self] in
            self?.onCornerRadiusChange?()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func invalidateContentSize() {
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width = max(0, size.width - padding * 2)
        let composerSize = composerView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: size.width, height: composerSize.height + padding * 2)
    }

    override var intrinsicContentSize: CGSize {
        let width = bounds.width > 0 ? bounds.width : UIView.layoutFittingExpandedSize.width
        return CGSize(width: UIView.noIntrinsicMetric, height: sizeThatFits(CGSize(width: width, height: 0)).height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let window {
            // The bar itself is short. Use a transparent, noninteractive reference
            // at window size so its resolved radius isn't limited by the bar's height.
            cornerReferenceView.frame = convert(window.bounds, from: window)
        }
        let width = max(0, bounds.width - padding * 2)
        let composerSize = composerView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        composerView.frame = CGRect(
            x: padding, y: padding, width: width, height: composerSize.height
        )
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0, isUserInteractionEnabled else { return nil }
        return composerView.hitTest(convert(point, to: composerView), with: event)
    }
}

private final class CornerReferenceView: UIView {
    private(set) var bottomCornerRadius: CGFloat = 0
    var onRadiusChange: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        cornerConfiguration = .corners(radius: .containerConcentric(minimum: 0))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = effectiveRadius(corner: [.bottomLeft, .bottomRight])
        guard radius != bottomCornerRadius else { return }
        bottomCornerRadius = radius
        onRadiusChange?()
    }
}
