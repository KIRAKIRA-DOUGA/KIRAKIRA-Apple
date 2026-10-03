import UIKit

final class SendTextInputView: UIView, UITextViewDelegate {
    private let glassContainer = UIVisualEffectView()
    private let fieldBackground = UIVisualEffectView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let emojiButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private var onTextChange: ((String) -> Void)?
    private var onSend: (() -> Void)?
    private var previousWidth: CGFloat = 0
    private var measuredTextWidth: CGFloat?
    private var measuredTextHeight: CGFloat = 0

    var onSizeChange: (() -> Void)?

    enum Metrics {
        static let minimumHeight: CGFloat = 40
        static let maximumHeight: CGFloat = 160
        static let padding: CGFloat = 8
        static let textLeading: CGFloat = padding * 2
        static let actionWidth: CGFloat = 38
        static let actionHeight: CGFloat = 28
        static let cornerRadius: CGFloat = 24
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        glassContainer.effect = UIGlassContainerEffect()
        let glass = UIGlassEffect(style: .regular)
        glass.isInteractive = true
        fieldBackground.effect = glass
        addButton.configuration = .glass()
        addSubview(glassContainer)
        glassContainer.contentView.addSubview(fieldBackground)
        glassContainer.contentView.addSubview(addButton)
        fieldBackground.layer.cornerCurve = .continuous
        fieldBackground.clipsToBounds = true
        fieldBackground.cornerConfiguration = .corners(radius: .fixed(Metrics.cornerRadius))

        textView.backgroundColor = .clear
        textView.textColor = .label
        textView.contentInsetAdjustmentBehavior = .never
        textView.contentInset = .zero
        textView.automaticallyAdjustsScrollIndicatorInsets = false
        textView.textContainer.lineFragmentPadding = 0
        textView.returnKeyType = .default
        textView.delegate = self
        textView.isScrollEnabled = false
        fieldBackground.contentView.addSubview(textView)

        placeholderLabel.textColor = .placeholderText
        placeholderLabel.isUserInteractionEnabled = false
        placeholderLabel.isAccessibilityElement = false
        fieldBackground.contentView.addSubview(placeholderLabel)

        addButton.configuration?.image = UIImage(
            systemName: "plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16)
        )
        addButton.configuration?.cornerStyle = .capsule
        addButton.accessibilityLabel = String(localized: .menuMore)
        emojiButton.setImage(UIImage(systemName: "face.smiling"), for: .normal)
        emojiButton.tintColor = .tertiaryLabel
        emojiButton.accessibilityLabel = String(localized: "Emoji")
        fieldBackground.contentView.addSubview(emojiButton)

        var sendConfiguration = UIButton.Configuration.filled()
        sendConfiguration.image = UIImage(
            systemName: "arrow.up",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        )
        sendConfiguration.cornerStyle = .capsule
        sendConfiguration.contentInsets = .zero
        sendButton.configuration = sendConfiguration
        sendButton.accessibilityLabel = String(localized: "ACTION_SEND")
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
        fieldBackground.contentView.addSubview(sendButton)
        addButton.isHidden = true
        sendButton.isHidden = true
        updateTypography()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
            (view: SendTextInputView, _: UITraitCollection) in
            view.updateTypography()
            view.updateContentLayout()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        text: String,
        prompt: String,
        showAddButton: Bool,
        onTextChange: @escaping (String) -> Void,
        onSend: @escaping () -> Void
    ) {
        self.onTextChange = onTextChange
        self.onSend = onSend
        // Avoid resetting the selection or interrupting marked text on unrelated SwiftUI updates.
        let textChanged = textView.text != text
        let visibilityChanged = addButton.isHidden != !showAddButton
        let promptChanged = placeholderLabel.text != prompt
        if textChanged {
            textView.text = text
            applyTextAttributes()
        }
        placeholderLabel.text = prompt
        textView.accessibilityLabel = prompt
        addButton.isHidden = !showAddButton
        if textChanged || visibilityChanged || promptChanged {
            updateContentLayout()
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        applyTextAttributes()
        updateContentLayout()
        onTextChange?(textView.text)
    }

    private func updateTypography() {
        let font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
        textView.font = font
        placeholderLabel.font = font
        textView.textContainerInset = UIEdgeInsets(
            top: textVerticalInset, left: 0, bottom: textVerticalInset, right: 0
        )
        applyTextAttributes()
    }

    private func applyTextAttributes() {
        // Do not restyle a Chinese/Japanese IME's provisional composition.
        guard textView.markedTextRange == nil else { return }
        let font = textView.font ?? .preferredFont(forTextStyle: .body)
        // An optical glyph adjustment keeps CJK text from sitting high in the native line box.
        // Unlike moving the editor or its insets, this leaves the line box in place.
        let baselineOffset = -UIFontMetrics(forTextStyle: .body).scaledValue(
            for: 1, compatibleWith: traitCollection
        )
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label,
            .baselineOffset: baselineOffset,
        ]
        textView.typingAttributes = attributes
        textView.textStorage.addAttributes(attributes, range: NSRange(location: 0, length: textView.textStorage.length))
    }

    private func updateContentLayout() {
        measuredTextWidth = nil
        placeholderLabel.isHidden = !textView.text.isEmpty
        sendButton.isHidden = textView.text.isEmpty
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        onSizeChange?()
    }

    private var lineHeight: CGFloat { textView.font?.lineHeight ?? 22 }

    private var initialHeight: CGFloat {
        min(Metrics.maximumHeight, max(Metrics.minimumHeight, lineHeight + Metrics.padding * 2))
    }

    private var textVerticalInset: CGFloat {
        (initialHeight - lineHeight) / 2
    }

    private var buttonAreaWidth: CGFloat {
        Metrics.actionWidth * (sendButton.isHidden ? 1 : 2) + Metrics.padding * 2
    }

    private var addButtonAreaWidth: CGFloat {
        addButton.isHidden ? 0 : addButtonSize + Metrics.padding
    }

    private var addButtonSize: CGFloat {
        44
    }

    private func textWidth(for width: CGFloat) -> CGFloat {
        max(1, width - addButtonAreaWidth - Metrics.textLeading - buttonAreaWidth)
    }

    private func textHeight(for width: CGFloat) -> CGFloat {
        if measuredTextWidth != width {
            measuredTextWidth = width
            measuredTextHeight = ceil(
                textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
            )
        }
        return measuredTextHeight
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height = textHeight(for: textWidth(for: size.width))
        return CGSize(width: size.width, height: max(initialHeight, min(height, Metrics.maximumHeight)))
    }

    override var intrinsicContentSize: CGSize {
        let height = bounds.width > 0 ? sizeThatFits(bounds.size).height : initialHeight
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if previousWidth != bounds.width {
            previousWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
        glassContainer.frame = bounds
        let leading = addButtonAreaWidth
        addButton.frame = CGRect(
            x: 0, y: bounds.height - (initialHeight + addButtonSize) / 2,
            width: addButtonSize, height: addButtonSize
        )
        fieldBackground.frame = CGRect(x: leading, y: 0, width: max(0, bounds.width - leading), height: bounds.height)
        let fieldWidth = fieldBackground.bounds.width
        let width = textWidth(for: bounds.width)
        let contentHeight = textHeight(for: width)
        textView.frame = CGRect(x: Metrics.textLeading, y: 0, width: width, height: bounds.height)
        let shouldScroll = contentHeight > bounds.height + 0.5
        if textView.isScrollEnabled != shouldScroll {
            textView.isScrollEnabled = shouldScroll
            if !shouldScroll {
                textView.setContentOffset(.zero, animated: false)
            }
        }
        if !placeholderLabel.isHidden {
            textView.layoutIfNeeded()
            placeholderLabel.font = textView.font
            let caretRect = textView.convert(
                textView.caretRect(for: textView.beginningOfDocument),
                to: fieldBackground.contentView
            )
            let placeholderHeight = placeholderLabel.sizeThatFits(
                CGSize(width: width, height: .greatestFiniteMagnitude)
            ).height
            placeholderLabel.frame = CGRect(
                x: caretRect.minX,
                y: caretRect.midY - placeholderHeight / 2,
                width: width,
                height: placeholderHeight
            )
        }
        // Lift the actions slightly for optical alignment, keeping their bottom offset fixed as text grows.
        let opticalOffset = UIFontMetrics(forTextStyle: .body).scaledValue(
            for: 2, compatibleWith: traitCollection
        )
        let actionBottomInset = (initialHeight - Metrics.actionHeight) / 2 + opticalOffset
        let actionY = fieldBackground.bounds.height - actionBottomInset - Metrics.actionHeight
        emojiButton.frame = CGRect(
            x: fieldWidth - buttonAreaWidth + Metrics.padding, y: actionY,
            width: Metrics.actionWidth, height: Metrics.actionHeight
        )
        sendButton.frame = CGRect(
            x: fieldWidth - Metrics.padding - Metrics.actionWidth, y: actionY,
            width: Metrics.actionWidth, height: Metrics.actionHeight
        )
    }

    @objc private func send() {
        guard !textView.text.isEmpty else { return }
        onSend?()
    }
}
