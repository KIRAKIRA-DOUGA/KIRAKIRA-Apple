import SwiftUI

struct SmartDateFormatStyle: FormatStyle {
    var absoluteThresholdInDays: Int = 7

    func format(_ value: Date) -> String {
        let calendar = Calendar.current
        let now = Date.now

        // Calculate the difference in days
        let components = calendar.dateComponents([.day], from: value, to: now)
        let daysDifference = abs(components.day ?? 0)

        if daysDifference < absoluteThresholdInDays {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.dateTimeStyle = .named
            return formatter.localizedString(for: value, relativeTo: now)

        } else {
            let currentYear = calendar.component(.year, from: now)
            let dateYear = calendar.component(.year, from: value)

            if currentYear == dateYear {
                // Same year: Omit the year component
                return value.formatted(
                    .dateTime
                        .month(.abbreviated)
                        .day()
                        .hour()
                        .minute()
                )
            } else {
                return value.formatted(date: .abbreviated, time: .shortened)
            }
        }
    }
}

extension FormatStyle where Self == SmartDateFormatStyle {
    static var smart: SmartDateFormatStyle {
        SmartDateFormatStyle()
    }

    static func smart(thresholdInDays: Int) -> SmartDateFormatStyle {
        SmartDateFormatStyle(absoluteThresholdInDays: thresholdInDays)
    }
}
