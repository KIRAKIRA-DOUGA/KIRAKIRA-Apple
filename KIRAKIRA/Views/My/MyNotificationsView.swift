//
//  MyNotificationsView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/12/2.
//

import SwiftUI

struct MyNotificationsView: View {
    var body: some View {
        List {
            Section {
                ForEach(1...2, id: \.self) { _ in
                    VStack(alignment: .leading) {
                        LabeledContent {
                            Text(verbatim: "2025/12/08")
                                .monospacedDigit()
                        } label: {
                            Text(verbatim: "昵称")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding(.trailing, 22)
                        Text(verbatim: "这是通知内容")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading) {
                    NavigationLink {
                        UserView()
                    } label: {
                        LabeledContent {
                            Text(verbatim: "2025/12/08")
                                .monospacedDigit()
                        } label: {
                            Text(verbatim: "这是一条可以点击的通知")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    Text("点击进入用户页")
                        .foregroundStyle(.secondary)
                }
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("NOTIFICATION")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MyNotificationsView()
}
