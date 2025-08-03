
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @Binding var isUserLoggedIn: Bool
    @AppStorage("expiringTaskNotifications") private var expiringTaskNotifications = true
    @AppStorage("newTaskNotifications") private var newTaskNotifications = true
    @AppStorage("weeklyProgressNotifications") private var weeklyProgressNotifications = true

    @State private var userEmail = ""
    @State private var phoneNumber = ""
    @State private var name = ""

    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false

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
            ScrollView {
                VStack(spacing: 24) {
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

                        inputRow(systemImage: "person", label: "Name", binding: .constant(name.isEmpty ? "No name set" : name), isEditable: false)

                        inputRow(systemImage: "envelope", label: "Email", binding: .constant(userEmail.isEmpty ? "No email set" : userEmail), isEditable: false)

                        inputRow(systemImage: "phone", label: "Phone", binding: $phoneNumber, isEditable: true)

                        NavigationLink(value: "Password") {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }

                    // NOTIFICATIONS
                    VStack(spacing: 12) {
                        Text("NOTIFICATIONS")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(gradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        Toggle("Expiring Tasks", isOn: $expiringTaskNotifications)
                            .tint(gradient)
                            .padding(10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .padding(.horizontal)

                        Toggle("New Tasks", isOn: $newTaskNotifications)
                            .tint(gradient)
                            .padding(10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .padding(.horizontal)

                        Toggle("Progress Reports", isOn: $weeklyProgressNotifications)
                            .tint(gradient)
                            .padding(10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .padding(.horizontal)
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
                            Text("Mode")
                            Spacer()
                            Text("Dark")
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // LOG OUT
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
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
                                    print("User signed out successfully.")
                                } catch {
                                    print("Error signing out: \(error.localizedDescription)")
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { value in
                if value == "Reset Password" {
                    ResetPasswordView()
                }
            }
            .onAppear {
                // Load cached data immediately
                if let cached = UserDefaults.standard.dictionary(forKey: "cachedUserData") {
                    self.name = cached["name"] as? String ?? ""
                    self.userEmail = cached["email"] as? String ?? ""
                }

                // Fetch fresh data from Firestore
                loadUserData()
            }

        }
        .preferredColorScheme(.dark)
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
            } else {
                print("Failed to fetch user data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    @ViewBuilder
    private func inputRow(systemImage: String, label: String, binding: Binding<String>, isEditable: Bool) -> some View {
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
