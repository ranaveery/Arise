import SwiftUI

struct HelpCenterView: View {
    var body: some View {
        InfoPageView(
            title: "Help Center",
            sections: [
                InfoPageSection(icon: "clock", title: "Response Time",
                    description: "We aim to respond within 24–48 hours. Please note that weekends may take longer."),
                InfoPageSection(icon: "checkmark.shield", title: "Common Issues",
                    description: "Restarting the app or ensuring you're on the latest version often resolves most issues."),
                InfoPageSection(icon: "envelope", title: "Contact Support",
                    description: "Email us at contact.arise.app@gmail.com with any issues or questions. Please include your User ID when contacting us by email.")
            ],
            footer: "We're here to help!"
        )
    }
}
