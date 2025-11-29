//
//  SearchView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct SearchView: View {
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 140), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    CategoryCard(name: "动画", icon: "forward.frame.fill")
                    CategoryCard(name: "音乐", icon: "music.note")
                    CategoryCard(name: "音MAD", icon: "megaphone.fill")
                    CategoryCard(name: "科技", icon: "cpu.fill")
                    CategoryCard(name: "设计", icon: "paintbrush.fill")
                    CategoryCard(name: "游戏", icon: "gamecontroller.fill")
                    CategoryCard(name: "综合", icon: "square.grid.2x2.fill")
                }.padding()
            }
            .navigationTitle("分区")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

private struct CategoryCard: View {
    let name: String
    let icon: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .foregroundStyle(.accent)
                .frame(minHeight: 110)
                .shadow(color: .accent.opacity(0.25), radius: 10, y: 10)
            HStack {
                VStack(alignment: .leading) {
                    Image(systemName: icon)
                        .font(.system(size: 25))
                        .opacity(0.8)
                    Spacer()
                    Text(name)
                        .bold()
                }
                .padding()
                Spacer()
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    //	MainView()
    SearchView()
}
