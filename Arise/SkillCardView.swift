import SwiftUI

struct SkillCardView: View {
    let symbolName: String
    let skillName: String
    let level: Int
    let progress: Double
    let trend: Int? // Use positive for up, negative for down
    let destination: AnyView
    let gradient: LinearGradient  // <- new

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(gradient)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(skillName)
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .semibold))

                        if let trend = trend {
                            Image(systemName: trend > 0 ? "arrow.up" : "arrow.down")
                                .scaledToFit()
                                .font(.caption)
                                .foregroundColor(trend > 0 ? .green : .red)
                        }
                    }

                    ZStack(alignment: .leading) {
                        Capsule()
                            .frame(width: 200, height: 6) //  fixed size for background
                            .foregroundColor(Color.gray.opacity(0.3))

                        Capsule()
                            .frame(width: CGFloat(progress) * 200, height: 6) // filled amount changes
                            .foregroundStyle(gradient)
                    }
                    .frame(maxWidth: 200)
                }

                Text("LVL \(level)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .fixedSize()
                    .padding(.leading, 8)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
