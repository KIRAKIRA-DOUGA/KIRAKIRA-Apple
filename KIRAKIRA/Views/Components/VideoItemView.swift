//
//  VideoItemView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/15.
//

import Flow
import SwiftUI

struct VideoItemView: View {
	//	let title: String?
	//	let uploader: String?
	//	let cover: URL?
	//	let viewCount: Int?
	//	let duration: String?
	//	let date: Date?

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			Image("SampleLandscape")
				.resizable()
				.aspectRatio(contentMode: .fill)
				.frame(
					minWidth: 0,
					maxWidth: .infinity,
					minHeight: 0,
					maxHeight: .infinity
				)
				.aspectRatio(16 / 9, contentMode: .fit)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				.allowsHitTesting(false)

			HStack(spacing: 10) {
				Text("艾了个拉")
				Text("7天前")
			}
			.font(.caption)
			.foregroundStyle(.secondary)
			.padding(.top, 8)
			.padding(.bottom, 4)
			Text("这是一个视频标题啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊")
				.lineLimit(2, reservesSpace: true)
			HStack(spacing: 10) {
				InfoItemView(systemImage: "play", text: "1145")
				InfoItemView(systemImage: "timer", text: "23:33")
			}
			.padding(.top, 6)
			.font(.caption)
			.foregroundStyle(.secondary)
		}
	}
}

#Preview {
	VideoItemView()
}
