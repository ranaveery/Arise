import SwiftUI

struct HelpCenterView: View {
    private var brandGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 84/255, green: 0/255, blue: 232/255),
                Color(red: 236/255, green: 71/255, blue: 1/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private let iconColumnWidth: CGFloat = 36
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Help Center")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(brandGradient)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                    
                    // Sections
                    helpSection(
                        icon: "clock",
                        title: "Response Time",
                        description: "We aim to respond within 24–48 hours. Please note that weekends may take longer."
                    )
                    
                    helpSection(
                        icon: "checkmark.shield",
                        title: "Common Issues",
                        description: "Restarting the app or ensuring you’re on the latest version often resolves most issues."
                    )
                    
                    helpSection(
                        icon: "envelope",
                        title: "Contact Support",
                        description: "Email us at contact.arise.app@gmail.com with any issues or questions. Please include your User ID when contacting us by email."
                    )
                    
                    // Footer
                    Text("We're here to help!")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 48)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private func helpSection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: iconColumnWidth, alignment: .center)
            
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
