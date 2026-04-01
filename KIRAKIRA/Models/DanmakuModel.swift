import Foundation

struct DanmakuResponseDTO: Codable {
    let danmaku: [DanmakuDTO]
}

struct DanmakuDTO: Codable, Identifiable {
    let _id: String
    let text: String  // the danmaku content
    let color: String  // hex color code, e.g. "#FFFFFF"
    let fontSize: DanmakuFontSize
    let mode: DanmakuPosition
    let time: TimeInterval
    let enableRainbow: Bool

    var id: String { _id }
}

enum DanmakuPosition: String, Codable {
    case rtl
    case ltr
    case top
    case bottom
}

enum DanmakuFontSize: String, Codable {
    case small
    case medium
    case large
}

// For rendering purposes only
struct ActiveDanmaku: Codable, Identifiable {
    let _id: String
    let text: String  // the danmaku content
    let color: String  // hex color code, e.g. "#FFFFFF"
    let fontSize: DanmakuFontSize
    let mode: DanmakuPosition
    let time: TimeInterval
    let enableRainbow: Bool

    var track: Int
    var speed: Int

    var id: String { _id }

    init(from danmakuDto: DanmakuDTO) {
        self._id = danmakuDto._id
        self.text = danmakuDto.text
        self.color = danmakuDto.color
        self.fontSize = danmakuDto.fontSize
        self.mode = danmakuDto.mode
        self.time = danmakuDto.time
        self.enableRainbow = danmakuDto.enableRainbow

        self.track = -1  // default value, will be assigned later
        self.speed = 100  // default speed, can be adjusted
    }
}
