import SwiftUI

struct PrivacyPolicyView: View {
    // Brand gradient
    private var brandGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 84/255, green: 0/255, blue: 232/255),
                Color(red: 236/255, green: 71/255, blue: 1/255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Fixed icon column width used for all rows (keeps text aligned)
    private let iconColumnWidth: CGFloat = 36

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Privacy Policy")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(brandGradient)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)

                    // Sections
                    policySection(
                        icon: "lock.shield",
                        title: "Data Collection",
                        description: "We only collect essential data needed to improve your experience and to make the app work for you."
                    )

                    policySection(
                        icon: "server.rack",
                        title: "Storage",
                        description: "All user data is stored securely using Firebase services. We follow recommended security practices to protect your information."
                    )

                    policySection(
                        icon: "nosign",
                        title: "No Data Selling",
                        description: "We never sell your personal data to third-party advertisers or brokers."
                    )

                    policySection(
                        icon: "trash",
                        title: "Data Deletion",
                        description: "You may request deletion of your account and personal data at any time by contacting support. We will process deletion requests in accordance with applicable law."
                    )

                    policySection(
                        icon: "clock.arrow.circlepath",
                        title: "Updates",
                        description: "We may revise this policy occasionally. Significant changes will be communicated to you via the app."
                    )

                    // Footer note
                    Text("By continuing to use this app, you agree to this privacy policy.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
                .padding(.horizontal, 16)   // horizontal padding applied once for perfect alignment
                .padding(.bottom, 48)      // bottom spacing for tab bar
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Section builder
    @ViewBuilder
    private func policySection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: iconColumnWidth, alignment: .center) // <-- fixed column width

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true) // allow multiline
            }
        }
        .padding(.vertical, 8)
    }
}
