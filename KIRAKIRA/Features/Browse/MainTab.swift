enum MainTab: Hashable {
    case home
    case feed
    case search
    case category(Category)

    // compact horizontal size only
    case me

    // regular horizontal size only
    case myNotifications
    case myMessages
    case myCollections
    case myHistory
    case myUserPage

    // These IDs are persisted in TabViewCustomization. Keep them stable when renaming cases.
    var customizationID: String {
        let identifier: String
        switch self {
        case .home: identifier = "home"
        case .feed: identifier = "following"
        case .search: identifier = "search"
        case .category(let category): identifier = "category.\(category.id)"
        case .me: identifier = "me"
        case .myNotifications: identifier = "notf"
        case .myMessages: identifier = "mesg"
        case .myCollections: identifier = "coll"
        case .myHistory: identifier = "history"
        case .myUserPage: identifier = "user"
        }
        return "moe.kirakira.tab.\(identifier)"
    }
}
