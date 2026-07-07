import SwiftUI

struct InfoPageSection: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct InfoPageView: View {
    let title: String
    let sections: [InfoPageSection]
    let footer: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(LinearGradient.brand)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)

                    ForEach(sections) { section in
                        sectionRow(icon: section.icon, title: section.title, description: section.description)
                    }

                    Text(footer)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func sectionRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 36, alignment: .center)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
    }
}
