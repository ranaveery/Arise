import SwiftUI

struct TermsOfUseView: View {
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
                    Text("Terms of Use")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(brandGradient)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                    
                    // Sections
                    termsSection(
                        icon: "person.crop.circle",
                        title: "Eligibility",
                        description: "You must be at least 13 years old to use the app. Parental consent is required for users under 18."
                    )
                    
                    termsSection(
                        icon: "iphone.homebutton",
                        title: "App Usage",
                        description: "Use the app responsibly. No harassment, abuse, or disruption of features is tolerated."
                    )
                    
                    termsSection(
                        icon: "doc.text",
                        title: "License",
                        description: "You are granted a non-transferable license to use the app for personal, non-commercial use only."
                    )
                    
                    termsSection(
                        icon: "gearshape.2",
                        title: "Modifications",
                        description: "We may change or remove features at any time without notice."
                    )
                    
                    termsSection(
                        icon: "xmark.octagon",
                        title: "Termination",
                        description: "Violation of these terms can result in account suspension or removal."
                    )
                    
                    termsSection(
                        icon: "exclamationmark.triangle",
                        title: "Disclaimer",
                        description: "The app is provided \"as is\" without warranties. We are not responsible for any losses or issues."
                    )
                    
                    // Footer
                    Text("By continuing to use this app, you agree to these terms.")
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
    private func termsSection(icon: String, title: String, description: String) -> some View {
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
