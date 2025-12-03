import Combine
import SwiftUI

public class AppSettings: ObservableObject {
    @AppStorage("videoDisplayStyle") var videoDisplayStyle: ViewStyle = .card
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true

    public static let shared = AppSettings()
}


/// A property wrapper that provides a binding to a value stored in `AppSettings`,
/// allowing views to read and write shared app configuration using a key path.
@propertyWrapper
public struct AppSetting<T>: DynamicProperty {
    @ObservedObject private var appSettings: AppSettings
    private let keyPath: ReferenceWritableKeyPath<AppSettings, T>

    public init(_ keyPath: ReferenceWritableKeyPath<AppSettings, T>, appSettings: AppSettings = .shared) {
        self.keyPath = keyPath
        self.appSettings = appSettings
    }

    public var wrappedValue: T {
        get { appSettings[keyPath: keyPath] }
        nonmutating set { appSettings[keyPath: keyPath] = newValue }
    }

    public var projectedValue: Binding<T> {
        Binding(
            get: { appSettings[keyPath: keyPath] },
            set: { value in
                appSettings[keyPath: keyPath] = value
            }
        )
    }
}

enum ViewStyle: String, CaseIterable, Identifiable {
    case row
    case card
    case smallCard

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .row:
            return "Row"
        case .card:
            return "Card"
        case .smallCard:
            return "Small Card"
        }
    }
}
