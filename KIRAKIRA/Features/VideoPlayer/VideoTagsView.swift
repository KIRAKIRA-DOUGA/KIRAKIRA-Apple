import Flow
import SwiftUI

struct VideoTagsView: View {
    let tags: [VideoTag]
    @Environment(\.locale) private var locale

    var body: some View {
        HFlow(alignment: .top, itemSpacing: 8, rowSpacing: 8) {
            ForEach(tags) { tag in
                Text(verbatim: tag.displayName(locale: locale))
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemFill), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum VideoTagsPreview {
    static let tags: [VideoTag] = [
        VideoTag(tagId: 1, tagNameList: [
            .init(lang: "zhs", tagName: [.init(name: "我的世界", isDefault: true)]),
            .init(lang: "zht", tagName: [.init(name: "當個創世神", isDefault: true)]),
            .init(lang: "en", tagName: [.init(name: "Minecraft", isDefault: true)]),
        ]),
        VideoTag(tagId: 2, tagNameList: [
            .init(lang: "other", tagName: [.init(name: "SwiftUI")]),
        ]),
        VideoTag(tagId: 3, tagNameList: [
            .init(lang: "zhs", tagName: [.init(name: "这是一个用于检查窄屏和辅助功能字号下自动换行的超长标签名称")]),
            .init(lang: "en", tagName: [.init(name: "A very long video tag for checking wrapping in narrow windows and accessibility text sizes")]),
        ]),
        VideoTag(tagId: 12345),
    ]
}

#Preview("简体 · 窄屏", traits: .sizeThatFitsLayout) {
    VideoTagsView(tags: VideoTagsPreview.tags)
        .padding()
        .frame(width: 320)
        .environment(\.locale, Locale(identifier: "zh-Hans"))
}

#Preview("English · Dark", traits: .sizeThatFitsLayout) {
    VideoTagsView(tags: VideoTagsPreview.tags)
        .padding()
        .frame(width: 480)
        .environment(\.locale, Locale(identifier: "en-US"))
        .preferredColorScheme(.dark)
}

#Preview("繁體 · 輔助功能字體", traits: .sizeThatFitsLayout) {
    VideoTagsView(tags: VideoTagsPreview.tags)
        .padding()
        .frame(width: 320)
        .environment(\.locale, Locale(identifier: "zh-Hant"))
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Empty", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        if ![VideoTag]().isEmpty {
            VideoTagsView(tags: [])
        }
    }
    .padding()
}
