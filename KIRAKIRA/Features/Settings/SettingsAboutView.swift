import SwiftUI

struct SettingsAboutView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
//                Image("Logo")
//                    .resizable()
//                    .frame(width: 200, height: 200)
//                    .padding(.top, -48)
                Image("AppIconStatic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.bottom)
                Image("BrandingText")
                Text(verbatim: "for Apple Devices")
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
                    Text(verbatim: "\(version) (\(build))")
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
