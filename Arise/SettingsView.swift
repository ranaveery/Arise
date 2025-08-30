import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Reusable top-level card so nested types can use it too
struct SectionCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.white.opacity(0.05)) // the card color you wanted
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

struct SettingsView: View {
    @Binding var isUserLoggedIn: Bool
    @AppStorage("expiringTasks") private var expiringTasks = true
    @AppStorage("newTasks") private var newTasks = true
    @AppStorage("weeklyProgress") private var weeklyProgress = true
    @State private var userEmail = ""
    @State private var name = ""
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var preferencesLoaded = false
    @State private var showGoogleSignInAlert = false
    @State private var navigateToChangePassword = false
    
//    let versionInfo = "1.0.0" // MAJOR.MINOR.PATCH
    let versionInfo = "0.3.2.0" // APPSTAGE.MAJOR.MINOR.PATCH

    let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 84/255, green: 0/255, blue: 232/255),
            Color(red: 236/255, green: 71/255, blue: 1/255)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 26) {
                    // HEADER
                    VStack(spacing: 4) {
                        Text("Settings")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("Customize your experience")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // ACCOUNT (title + card grouped)
                    sectionBlock("ACCOUNT") {
                        inputRow(systemImage: "person", label: "Name", binding: $name, isEditable: true) {
                            saveNameToFirestore(name)
                        }
                        dividerLine()
                        inputRow(systemImage: "envelope",
                                 label: "Email",
                                 binding: .constant(userEmail.isEmpty ? "No email set" : userEmail),
                                 isEditable: false)
                        dividerLine()
                        navRow(systemImage: "slider.horizontal.3", label: "Preferences") { ManagePreferencesView() }
                        dividerLine()
                        buttonRow(systemImage: "lock.rotation", label: "Change Password") {
                            if let provider = Auth.auth().currentUser?.providerData.first?.providerID,
                               provider == "password" {
                                navigateToChangePassword = true
                            } else {
                                showGoogleSignInAlert = true
                            }
                        }
                        .alert(isPresented: $showGoogleSignInAlert) {
                            Alert(
                                title: Text("Cannot Change Password"),
                                message: Text("This account was created with Google Sign-In, so no password is stored. To update your password, please use your Google Account settings."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                        dividerLine()
                        navRow(systemImage: "trash", label: "Delete Account") {
                            DeleteAccountView(isUserLoggedIn: $isUserLoggedIn)
                        }
                    }

                    // NOTIFICATIONS (title + card grouped)
                    sectionBlock("NOTIFICATIONS") {
                        notificationsContent()
                    }

                    // APPEARANCE
                    sectionBlock("APPEARANCE") {
                        staticRow(systemImage: "circle.lefthalf.filled", label: "Mode", value: "Dark")
                        dividerLine()
                        staticRow(systemImage: "circle.dotted.and.circle", label: "Animations", value: "Enabled")
                    }

                    // APP / ABOUT
                    sectionBlock("APP") {
                        appRow(systemImage: "questionmark.circle", label: "Help Center") { HelpCenterView() }
                        dividerLine()
                        appRow(systemImage: "doc.text", label: "Terms of Use") { TermsOfUseView() }
                        dividerLine()
                        appRow(systemImage: "lock.shield", label: "Privacy Policy") { PrivacyPolicyView() }
                        dividerLine()
                        userIDRow()
                        dividerLine()
                        staticRow(systemImage: "info.circle", label: "Version", value: versionInfo)
                    }

                    // LOG OUT
                    Button(action: { showLogoutConfirmation = true }) {
                        Text("Log Out")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                    }
                    .alert(isPresented: $showLogoutConfirmation) {
                        Alert(
                            title: Text("Are you sure?"),
                            message: Text("Do you really want to log out?"),
                            primaryButton: .destructive(Text("Log Out")) {
                                do {
                                    try Auth.auth().signOut()
                                    isUserLoggedIn = false
                                } catch {
                                    print("Error signing out: \(error.localizedDescription)")
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .padding(.bottom, 100)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { value in
                if value == "Reset Password" { ResetPasswordView() }
            }
            .navigationDestination(isPresented: $navigateToChangePassword) {
                ChangePasswordView()
            }
            .onAppear {
                if let cached = UserDefaults.standard.dictionary(forKey: "cachedUserData") {
                    self.name = cached["name"] as? String ?? ""
                    self.userEmail = cached["email"] as? String ?? ""
                }
                loadUserData()
                loadPreferences()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - SECTION BLOCK (title + card grouped)
    private func sectionBlock<Content: View>(_ title: String,
                                             @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.headline).fontWeight(.semibold)
                .foregroundStyle(gradient)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 0)

            SectionCard {
                // add a tiny top padding inside the card so content isn't glued to the corner
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    // MARK: - Notifications content (content-only, wrapped by sectionBlock)
    @ViewBuilder
    private func notificationsContent() -> some View {
        Toggle(isOn: $expiringTasks) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark").foregroundColor(.gray).frame(width: 20)
                Text("Expiring Tasks").foregroundColor(.white)
            }
        }
        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
        .padding(.horizontal)
        .padding(.vertical, 12)

        dividerLine()

        Toggle(isOn: $newTasks) {
            HStack {
                Image(systemName: "plus.square.on.square").foregroundColor(.gray).frame(width: 20)
                Text("New Tasks").foregroundColor(.white)
            }
        }
        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
        .padding(.horizontal)
        .padding(.vertical, 12)

        dividerLine()

        Toggle(isOn: $weeklyProgress) {
            HStack {
                Image(systemName: "chart.bar.xaxis").foregroundColor(.gray).frame(width: 20)
                Text("Progress Reports").foregroundColor(.white)
            }
        }
        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Divider between rows (no gaps)
    private func dividerLine() -> some View {
        Divider()
            .background(Color.gray.opacity(0.01))
            .padding(.leading, 45) // align with text after the icon
    }

    // MARK: - Reusable Rows
    private func staticRow(systemImage: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: systemImage).foregroundColor(.gray).frame(width: 20)
            Text(label).foregroundColor(.white)
            Spacer()
            Text(value).foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func navRow<Destination: View>(systemImage: String, label: String, destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                Image(systemName: systemImage).foregroundColor(.gray).frame(width: 20)
                Text(label).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    private func buttonRow(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage).foregroundColor(.gray).frame(width: 20)
                Text(label).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func appRow<Destination: View>(systemImage: String, label: String, destination: @escaping () -> Destination) -> some View {
        navRow(systemImage: systemImage, label: label, destination: destination)
    }

    private func userIDRow() -> some View {
        HStack {
            Image(systemName: "grid.circle")
                .foregroundColor(.gray)
                .frame(width: 20)
            Text("User ID").foregroundColor(.white)
            Spacer()
            if let user = Auth.auth().currentUser {
                Text(user.uid)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func inputRow(
        systemImage: String,
        label: String,
        binding: Binding<String>,
        isEditable: Bool,
        onCommit: (() -> Void)? = nil
    ) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 20)
            Text(label)
                .foregroundColor(.white)
            Spacer()
            if isEditable {
                TextField("", text: binding)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.white)
                    .frame(minWidth: 100)
                    .onSubmit { onCommit?() }
            } else {
                Text(binding.wrappedValue)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Firestore helpers
    private func saveNameToFirestore(_ newName: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "name": newName
        ], merge: true) { error in
            if let error = error {
                print("Failed to update name: \(error.localizedDescription)")
            } else {
                var cached = UserDefaults.standard.dictionary(forKey: "cachedUserData") ?? [:]
                cached["name"] = newName
                UserDefaults.standard.set(cached, forKey: "cachedUserData")
            }
        }
    }

    private func loadPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                if let notifications = data["notifications"] as? [String: Bool] {
                    expiringTasks = notifications["expiringTasks"] ?? true
                    newTasks = notifications["newTasks"] ?? true
                    weeklyProgress = notifications["weeklyProgress"] ?? true
                } else {
                    PreferenceManager.savePreference(key: "expiringTasks", value: true)
                    PreferenceManager.savePreference(key: "newTasks", value: true)
                    PreferenceManager.savePreference(key: "weeklyProgress", value: true)
                }
            }
            preferencesLoaded = true
        }
    }

    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                let fetchedName = data["name"] as? String ?? ""
                let fetchedEmail = data["email"] as? String ?? ""
                DispatchQueue.main.async {
                    self.name = fetchedName
                    self.userEmail = fetchedEmail
                }
                UserDefaults.standard.set(["name": fetchedName, "email": fetchedEmail], forKey: "cachedUserData")
            }
        }
    }

    struct PreferenceManager {
        static func savePreference(key: String, value: Bool) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            db.collection("users").document(uid).setData([
                "notifications": [key: value]
            ], merge: true)
        }
    }
}
