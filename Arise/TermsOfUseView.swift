import SwiftUI

struct TermsOfUseView: View {
    var body: some View {
        InfoPageView(
            title: "Terms of Use",
            sections: [
                InfoPageSection(icon: "person.crop.circle", title: "Eligibility",
                    description: "You must be at least 9 years old to use the app."),
                InfoPageSection(icon: "iphone.homebutton", title: "App Usage",
                    description: "Use the app responsibly. No harassment, abuse, or disruption of features is tolerated."),
                InfoPageSection(icon: "gearshape.2", title: "Modifications",
                    description: "We may change or remove features at any time without notice."),
                InfoPageSection(icon: "xmark.octagon", title: "Termination",
                    description: "Violation of these terms can result in account suspension or removal."),
                InfoPageSection(icon: "exclamationmark.triangle", title: "Disclaimer",
                    description: "The app is provided \"as is\" without warranties. We are not responsible for any losses or issues.")
            ],
            footer: "By continuing to use this app, you agree to these terms."
        )
    }
}
