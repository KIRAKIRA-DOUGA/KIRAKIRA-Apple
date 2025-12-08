//
//  MyMessagesView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/12/2.
//

import SwiftUI

struct MyMessagesView: View {
    var body: some View {
        List {
            Section {
                ForEach(1...10, id: \.self) { _ in
                    HStack(spacing: 16) {
                        HStack {
                            Circle()
                                .foregroundStyle(.accent)
                                .frame(width: 10, height: 10)
                            Image("SamplePortrait")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        VStack(alignment: .leading) {
                            NavigationLink {
                                Text(verbatim: "私聊界面")
                            } label: {
                                LabeledContent {
                                    Text(verbatim: "2025/12/08")
                                        .monospacedDigit()
                                } label: {
                                    Text(verbatim: "昵称")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                            }
                            Text(
                                verbatim:
                                    "Hello world!~ Hello world!~ Hello world!~ Hello world!~ Hello world!~ Hello world!~ "
                            )
                            .foregroundStyle(.secondary)
                            .lineLimit(2, reservesSpace: true)
                        }
                    }
                }
                .onDelete(perform: { _ in print("hello") })
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("MESSAGES")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MyMessagesView()
}
