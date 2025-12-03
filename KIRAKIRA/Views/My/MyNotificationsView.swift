//
//  MyNotificationsView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/12/2.
//

import SwiftUI

struct MyNotificationsView: View {
    var body: some View {
        Form {
            ForEach(1...3, id: \.self) { _ in
                VStack(alignment: .leading) {
                    Text("这是通知标题")
                        .font(.headline)
                    Text("这是通知内容")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("通知")
    }
}

#Preview {
    MyNotificationsView()
}
