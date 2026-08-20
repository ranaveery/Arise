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
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                            sectionRow(icon: section.icon, title: section.title, description: section.description)
                            if index < sections.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )

                    Text(footer)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.45))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
