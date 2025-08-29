import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
    let versionInfo = "0.3.1.3" // APPSTAGE.MAJOR.MINOR.PATCH
    
    
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
                VStack(spacing: 30) {
                    VStack(spacing: 4) {
                        Text("Settings")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        Text("Customize your experience")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)
                    
                    // ACCOUNT
                    VStack(spacing: 12) {
                        Text("ACCOUNT")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(gradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        //                        inputRow(systemImage: "person", label: "Name", binding: .constant(name.isEmpty ? "No name set" : name), isEditable: false)
                        inputRow(systemImage: "person", label: "Name", binding: $name, isEditable: true) {
                            saveNameToFirestore(name)
                        }
                        inputRow(systemImage: "envelope", label: "Email", binding: .constant(userEmail.isEmpty ? "No email set" : userEmail), isEditable: false)
                        
                        // Preferences row
                        NavigationLink(destination: ManagePreferencesView()) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                Text("Preferences")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                        HStack {
                            Button(action: {
                                if let provider = Auth.auth().currentUser?.providerData.first?.providerID,
                                   provider == "password" {
                                    // Navigate to ChangePasswordView
                                    // If using NavigationLink programmatically:
                                    navigateToChangePassword = true
                                } else {
                                    // Show alert for Google sign-in users
                                    showGoogleSignInAlert = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    Text("Change Password")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            .alert(isPresented: $showGoogleSignInAlert) {
                                Alert(
                                    title: Text("Cannot Change Password"),
                                    message: Text("This account was created with Google Sign-In, so no password is stored. To update your password, please use your Google Account settings."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                        
                        NavigationLink(destination: DeleteAccountView(isUserLoggedIn: $isUserLoggedIn)) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                Text("Delete Account")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                    }
                    
                    NotificationsSection()
                    
                    // APPEARANCE
                    VStack(spacing: 12) {
                        Text("APPEARANCE")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(gradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            Text("Mode").foregroundColor(.white)
                            Spacer()
                            Text("Dark").foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "circle.dotted.and.circle")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            Text("Animations").foregroundColor(.white)
                            Spacer()
                            Text("Enabled").foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // ABOUT
                    VStack(spacing: 12) {
                        Text("ABOUT")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(gradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        aboutRow(systemImage: "questionmark.circle", label: "Help Center") { HelpCenterView() }
                        aboutRow(systemImage: "doc.text", label: "Terms of Use") { TermsOfUseView() }
                        aboutRow(systemImage: "lock.shield", label: "Privacy Policy") { PrivacyPolicyView() }
                        
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
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            Text("Version").foregroundColor(.white)
                            Spacer()
                            Text(versionInfo).foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.horizontal)
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
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                    .background(Color.black)
                }
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
    
    private func saveNameToFirestore(_ newName: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "name": newName
        ], merge: true) { error in
            if let error = error {
                print("Failed to update name: \(error.localizedDescription)")
            } else {
                print("Name successfully updated to: \(newName)")
                // Optionally update UserDefaults cache
                var cached = UserDefaults.standard.dictionary(forKey: "cachedUserData") ?? [:]
                cached["name"] = newName
                UserDefaults.standard.set(cached, forKey: "cachedUserData")
            }
        }
    }
    
    func loadPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                if let notifications = data["notifications"] as? [String: Bool] {
                    expiringTasks = notifications["expiringTasks"] ?? true
                    newTasks = notifications["newTasks"] ?? true
                    weeklyProgress = notifications["weeklyProgress"] ?? true
                } else {
                    // If missing, set defaults in Firestore
                    PreferenceManager.savePreference(key: "expiringTasks", value: true)
                    PreferenceManager.savePreference(key: "newTasks", value: true)
                    PreferenceManager.savePreference(key: "weeklyProgress", value: true)
                }
            }
            preferencesLoaded = true // safe to show toggles
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
    
    @ViewBuilder
    private func aboutRow<Destination: View>(systemImage: String, label: String, destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                Image(systemName: systemImage).foregroundColor(.gray).frame(width: 20)
                Text(label).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    
    @ViewBuilder
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
                    .onSubmit {    // fires when user presses return or ends editing
                        onCommit?()
                    }
            } else {
                Text(binding.wrappedValue)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    
    // MARK: - Notifications Section
    struct NotificationsSection: View {
        // Local persisted states (load instantly from UserDefaults)
        @AppStorage("expiringTasks") private var expiringTasks = true
        @AppStorage("newTasks") private var newTasks = true
        @AppStorage("weeklyProgress") private var weeklyProgress = true
        
        let gradient = LinearGradient(
            colors: [Color(red: 84/255, green: 0/255, blue: 232/255), Color(red: 236/255, green: 71/255, blue: 1/255)],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        var body: some View {
            VStack(spacing: 12) {
                Text("NOTIFICATIONS")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(gradient)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                notificationToggle(systemImage: "clock.badge.exclamationmark",
                                   label: "Expiring Tasks",
                                   isOn: $expiringTasks)
                .onChange(of: expiringTasks) { _, newValue in
                    PreferenceManager.savePreference(key: "expiringTasks", value: newValue)
                }
                
                notificationToggle(systemImage: "plus.square.on.square",
                                   label: "New Tasks",
                                   isOn: $newTasks)
                .onChange(of: newTasks) { _, newValue in
                    PreferenceManager.savePreference(key: "newTasks", value: newValue)
                }
                
                notificationToggle(systemImage: "chart.bar.xaxis",
                                   label: "Progress Reports",
                                   isOn: $weeklyProgress)
                .onChange(of: weeklyProgress) { _, newValue in
                    PreferenceManager.savePreference(key: "weeklyProgress", value: newValue)
                }
            }
            .onAppear {
                refreshPreferencesFromFirestore()
            }
        }
        
        
        @ViewBuilder
        private func notificationToggle(systemImage: String, label: String, isOn: Binding<Bool>) -> some View {
            Toggle(isOn: isOn) {
                HStack {
                    Image(systemName: systemImage).foregroundColor(.gray).frame(width: 20)
                    Text(label).foregroundColor(.white)
                }
            }
            .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        
        private func refreshPreferencesFromFirestore() {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            db.collection("users").document(uid).getDocument { snapshot, error in
                if let data = snapshot?.data(),
                   let notifications = data["notifications"] as? [String: Bool] {
                    // Update AppStorage with cloud values (overrides cache if different)
                    expiringTasks = notifications["expiringTasks"] ?? expiringTasks
                    newTasks = notifications["newTasks"] ?? newTasks
                    weeklyProgress = notifications["weeklyProgress"] ?? weeklyProgress
                }
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
