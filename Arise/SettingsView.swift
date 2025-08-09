import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @Binding var isUserLoggedIn: Bool
    @AppStorage("expiringTaskNotifications") private var expiringTaskNotifications = true
    @AppStorage("newTaskNotifications") private var newTaskNotifications = true
    @AppStorage("weeklyProgressNotifications") private var weeklyProgressNotifications = true

    @State private var userEmail = ""
    @State private var name = ""
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var preferencesLoaded = false // ✅ new

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

                        inputRow(systemImage: "person", label: "Name", binding: .constant(name.isEmpty ? "No name set" : name), isEditable: false)
                        inputRow(systemImage: "envelope", label: "Email", binding: .constant(userEmail.isEmpty ? "No email set" : userEmail), isEditable: false)

                        if let provider = Auth.auth().currentUser?.providerData.first?.providerID,
                           provider == "password" {
                            NavigationLink(value: "Password") {
                                Text("Change Password")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(10)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                            }
                        }
                    }

                    // NOTIFICATIONS
                    if preferencesLoaded { // ✅ only show after loaded
                        VStack(spacing: 12) {
                            Text("NOTIFICATIONS")
                                .font(.title3)
                                .bold()
                                .foregroundStyle(gradient)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            notificationToggle(systemImage: "clock.badge.exclamationmark", label: "Expiring Tasks", isOn: $expiringTaskNotifications)
                                .onChange(of: expiringTaskNotifications) { _, newValue in
                                    savePreference(key: "expiringTasks", value: newValue)
                                }

                            notificationToggle(systemImage: "plus.square.on.square", label: "New Tasks", isOn: $newTaskNotifications)
                                .onChange(of: newTaskNotifications) { _, newValue in
                                    savePreference(key: "newTasks", value: newValue)
                                }

                            notificationToggle(systemImage: "chart.bar.xaxis", label: "Progress Reports", isOn: $weeklyProgressNotifications)
                                .onChange(of: weeklyProgressNotifications) { _, newValue in
                                    savePreference(key: "weeklyProgress", value: newValue)
                                }
                        }
                    }

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
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            Text("Version").foregroundColor(.white)
                            Spacer()
                            Text("v.25.7.1").foregroundColor(.gray)
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
                            .background(Color(red: 236/255, green: 71/255, blue: 1/255))
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

    func savePreference(key: String, value: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "notifications": [ key: value ]
        ], merge: true)
    }

    func loadPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                if let notifications = data["notifications"] as? [String: Bool] {
                    expiringTaskNotifications = notifications["expiringTasks"] ?? true
                    newTaskNotifications = notifications["newTasks"] ?? true
                    weeklyProgressNotifications = notifications["weeklyProgress"] ?? true
                } else {
                    // ✅ If missing, set defaults in Firestore
                    savePreference(key: "expiringTasks", value: true)
                    savePreference(key: "newTasks", value: true)
                    savePreference(key: "weeklyProgress", value: true)
                }
            }
            preferencesLoaded = true // ✅ safe to show toggles
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
    private func notificationToggle(systemImage: String, label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack {
                Image(systemName: systemImage).foregroundColor(.gray).frame(width: 20)
                Text(label).foregroundColor(.white)
            }
        }
        .tint(gradient)
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func inputRow(systemImage: String, label: String, binding: Binding<String>, isEditable: Bool) -> some View {
        HStack {
            Image(systemName: systemImage).foregroundColor(.gray).frame(width: 20)
            Text(label).foregroundColor(.white)
            Spacer()
            if isEditable {
                TextField("", text: binding)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.white)
                    .frame(minWidth: 100)
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
}
