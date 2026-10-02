import SwiftUI

struct SearchView: View {
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 140), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Category.allCases) { category in
                        CategoryCard(name: category.name, icon: category.systemImage, color: category.color)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(.search)
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

private struct CategoryCard: View {
    let name: String
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(UIColor.secondarySystemGroupedBackground))
                .frame(minHeight: 100)
            HStack {
                VStack(alignment: .leading) {
                    Image(systemName: icon)
                        .font(.system(size: 25))
                        .opacity(0.8)
                        .foregroundStyle(color)
                    Spacer()
                    Text(name)
                        .bold()
                }
                .padding()
                Spacer()
            }
        }
    }
}

#Preview {
    SearchView()
}
