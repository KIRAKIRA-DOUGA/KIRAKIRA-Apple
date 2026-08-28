import SwiftUI

struct EditTagView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(verbatim: "我的世界")
                    Text(verbatim: "麦块")
                    Text(verbatim: "当个创世神")

                    Button("添加别名", systemImage: "plus") {

                    }
                } header: {
                    Text(verbatim: "简体中文")
                }

                Section {
                    LabeledContent {
                        Text(verbatim: "原名")
                    } label: {
                        Text(verbatim: "Minecraft")
                    }

                    Text(verbatim: "MC")

                    Button("添加别名", systemImage: "plus") {

                    }
                } header: {
                    Text(verbatim: "英语")
                }

                Button("添加语言", systemImage: "plus") {

                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close, action: { dismiss() })
                }

                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .navigationTitle("编辑标签")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    EditTagView()
}
