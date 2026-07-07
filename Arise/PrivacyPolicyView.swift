import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        InfoPageView(
            title: "Privacy Policy",
            sections: [
                InfoPageSection(icon: "lock.shield", title: "Data Collection",
                    description: "We only collect essential data needed to improve your experience and to make the app work for you."),
                InfoPageSection(icon: "server.rack", title: "Storage",
                    description: "All user data is stored securely using Firebase services. We follow recommended security practices to protect your information."),
                InfoPageSection(icon: "nosign", title: "No Data Selling",
                    description: "We never sell your personal data to third-party advertisers or brokers."),
                InfoPageSection(icon: "trash", title: "Data Deletion",
                    description: "You may request deletion of your account and personal data at any time by contacting support. We will process deletion requests in accordance with applicable law."),
                InfoPageSection(icon: "clock.arrow.circlepath", title: "Updates",
                    description: "We may revise this policy occasionally. Significant changes will be communicated to you via the app.")
            ],
            footer: "By continuing to use this app, you agree to this privacy policy."
        )
    }
}
