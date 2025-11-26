//
//  VideoListItemView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/23.
//

import SwiftUI

struct VideoListItemView: View {
	//	let title: String?
	//	let uploader: String?
	//	let cover: URL?
	//	let viewCount: Int?
	//	let duration: String?
	//	let date: Date?

	var body: some View {
		HStack(spacing: 10) {
			Image("SampleLandscape")
				.resizable()
				.scaledToFill()
				.frame(
					minWidth: 0,
					maxWidth: .infinity,
					minHeight: 0,
					maxHeight: .infinity
				)
				.aspectRatio(16 / 9, contentMode: .fit)
				.frame(width: 140)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				.allowsHitTesting(false)
				.padding(.leading)
			VStack(alignment: .leading, spacing: 0) {
				HStack(spacing: 10) {
					//						Text("艾了个拉")
					Text("7天前")
				}.padding(.bottom, 4)
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(
					"这是一个视频这是一个视频这是一个视频这是一个视频这是一个视频这是一个视频这是一个视频这是一个视频这是一个视频这是一个视频"
				)
				.lineLimit(2, reservesSpace: true)
				HStack(spacing: 10) {
					InfoItemView(systemImage: "play", text: "1145")
					InfoItemView(systemImage: "timer", text: "23:33")
				}
				.font(.caption)
				.foregroundStyle(.secondary)
				.padding(.top, 6)
				Divider().padding(.top, 12)
			}
			.padding(.trailing)
			.padding(.top, 12)
		}
	}
}

#Preview {
	VideoListItemView()
}
