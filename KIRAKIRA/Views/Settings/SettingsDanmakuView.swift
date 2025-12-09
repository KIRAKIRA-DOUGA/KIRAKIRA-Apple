//
//  SettingsDanmakuView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/30.
//

import SwiftUI

struct SettingsDanmakuView: View {
    @State var danmakuSize = 17.0
    @State var danmakuOpacity = 1.0
    @State var danmakuSpeed = 3.0

    var body: some View {
        List {
            ZStack {
                Image("SampleLandscape")
                    .resizable()
                    .aspectRatio(16 / 9, contentMode: .fill)
                Text(verbatim: "这是一条弹幕")
                    .font(.system(size: danmakuSize))
                    .opacity(danmakuOpacity)
                    .shadow(color: .black, radius: 1)
                    .foregroundStyle(.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .listRowBackground(Color.clear)

            Section(header: Text("SETTINGS_DANMAKU_SIZE")) {
                HStack {
                    Image(systemName: "textformat.size")
                        .frame(width: 36)
                        .foregroundStyle(.secondary)
                    Slider(value: $danmakuSize, in: 9...25, step: 1)
                    Text(Int(danmakuSize), format: .number)
                        .frame(width: 36)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: danmakuSize))
                }
            }

            Section(header: Text("SETTINGS_DANMAKU_OPACITY")) {
                HStack {
                    Image(systemName: "circle.lefthalf.filled")
                        .frame(width: 36)
                        .foregroundStyle(.secondary)
                    Slider(value: $danmakuOpacity, in: 0.1...1)
                    Text(danmakuOpacity, format: .percent)
                        .frame(width: 36)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: danmakuOpacity))
                }
            }

            Section(header: Text("SETTINGS_DANMAKU_SPEED")) {
                Slider(value: $danmakuSpeed, in: 1...5, step: 1) {

                } minimumValueLabel: {
                    Image(systemName: "tortoise.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 36)
                } maximumValueLabel: {
                    Image(systemName: "hare.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 36)
                }
            }
        }.navigationTitle("SETTINGS_DANMAKU")
    }
}

#Preview {
    SettingsDanmakuView()
}
