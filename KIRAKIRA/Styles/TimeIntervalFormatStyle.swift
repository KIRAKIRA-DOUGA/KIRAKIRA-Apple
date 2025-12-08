import SwiftUI

struct TimeIntervalFormatStyle: FormatStyle {
    func format(_ value: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: value) ?? ""
    }
}

extension FormatStyle where Self == TimeIntervalFormatStyle {
    static var timeInterval: TimeIntervalFormatStyle { TimeIntervalFormatStyle() }
}
