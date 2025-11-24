//
//  SettingsAboutView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/12.
//

import SwiftUI

struct SettingsAboutView: View {
	var body: some View {
		ZStack {
			VStack(spacing: 8) {
				//				Image("BrandingTextWithLogo")
				//					.foregroundStyle(.accent)
				//					.padding(EdgeInsets(top: -12, leading: 1, bottom: 0, trailing: -10))
				Image("Logo")
					.resizable()
					.frame(width: 200, height: 200)
					.padding(.top, -48)
				Image("BrandingText")
				Text("for Apple Devices")
					.fontWeight(.semibold)
			}
			.foregroundStyle(.accent)

			VStack {
				Spacer()
				if let version = Bundle.main.object(
					forInfoDictionaryKey: "CFBundleShortVersionString"
				) as? String,
					let build = Bundle.main.object(
						forInfoDictionaryKey: "CFBundleVersion"
					) as? String
				{
					Text("\(version) (\(build))")
						.textSelection(.enabled)
				}
			}
			.foregroundStyle(.secondary)
			.padding()
		}
	}
}

#Preview {
	SettingsAboutView()
}
