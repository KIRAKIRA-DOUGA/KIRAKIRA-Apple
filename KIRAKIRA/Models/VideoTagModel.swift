import Foundation

nonisolated struct VideoTag: Codable, Equatable, Sendable, Identifiable {
    struct LocalizedNames: Codable, Equatable, Sendable {
        let lang: String
        let tagName: [Name]

        init(lang: String, tagName: [Name] = []) {
            self.lang = lang
            self.tagName = tagName
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            lang = try container.decode(String.self, forKey: .lang)
            tagName = try container.decodeIfPresent([Name].self, forKey: .tagName) ?? []
        }
    }

    struct Name: Codable, Equatable, Sendable {
        let name: String
        let isDefault: Bool
        let isOriginalTagName: Bool

        init(name: String, isDefault: Bool = false, isOriginalTagName: Bool = false) {
            self.name = name
            self.isDefault = isDefault
            self.isOriginalTagName = isOriginalTagName
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
            isOriginalTagName = try container.decodeIfPresent(Bool.self, forKey: .isOriginalTagName) ?? false
        }

        fileprivate var hasDisplayName: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    let tagId: Int
    let tagNameList: [LocalizedNames]

    var id: Int { tagId }

    init(tagId: Int, tagNameList: [LocalizedNames] = []) {
        self.tagId = tagId
        self.tagNameList = tagNameList
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagId = try container.decode(Int.self, forKey: .tagId)
        tagNameList = try container.decodeIfPresent([LocalizedNames].self, forKey: .tagNameList) ?? []
    }

    func displayName(locale: Locale) -> String {
        let language = locale.language.languageCode?.identifier.lowercased() ?? ""
        let isTraditionalChinese = locale.language.script?.identifier == "Hant"
            || ["TW", "HK", "MO"].contains(locale.region?.identifier ?? "")
        let wireLanguage = language == "zh" ? (isTraditionalChinese ? "zht" : "zhs") : language
        let identifier = locale.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        let chineseAlias = isTraditionalChinese ? "zh-hant" : "zh-hans"

        func group(for identifier: String) -> LocalizedNames? {
            tagNameList.first {
                $0.lang.replacingOccurrences(of: "_", with: "-").lowercased() == identifier
            }
        }

        let selected = group(for: wireLanguage)
            ?? group(for: identifier)
            ?? (language == "zh" ? group(for: chineseAlias) : nil)
            ?? group(for: "other")
            ?? tagNameList.first
        let names = selected?.tagName ?? []
        return names.first { $0.isDefault && $0.hasDisplayName }?.name
            ?? names.first { $0.hasDisplayName }?.name
            ?? "#\(tagId)"
    }
}
