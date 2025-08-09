import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            Image("logo_arise")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
                .padding(.top, 10)

            Text("Change Password")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            VStack(spacing: 16) {
                SecureField("Current Password", text: $currentPassword)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    .foregroundColor(.white)

                SecureField("New Password", text: $newPassword)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    .foregroundColor(.white)

                SecureField("Confirm New Password", text: $confirmNewPassword)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    .foregroundColor(.white)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, -4)
                }

                if !successMessage.isEmpty {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, -4)
                }
            }

            Button(action: changePassword) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(25)
                } else {
                    Text("Update Password")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 84/255, green: 0/255, blue: 232/255),
                                Color(red: 236/255, green: 71/255, blue: 1/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }

    private func changePassword() {
        errorMessage = ""
        successMessage = ""
        
        guard !currentPassword.isEmpty else {
            errorMessage = "Please enter your current password."
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "New password must be at least 6 characters."
            return
        }
        
        guard newPassword == confirmNewPassword else {
            errorMessage = "New passwords do not match."
            return
        }
        
        guard let user = Auth.auth().currentUser, let email = user.email else {
            errorMessage = "User not logged in."
            return
        }
        
        isLoading = true
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { _, error in
            if let _ = error {
                self.errorMessage = "Current password is incorrect."
                self.isLoading = false
                return
            }
            
            user.updatePassword(to: newPassword) { error in
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to update password: \(error.localizedDescription)"
                } else {
                    self.successMessage = "Password updated successfully."
                    self.currentPassword = ""
                    self.newPassword = ""
                    self.confirmNewPassword = ""
                }
            }
        }
    }
}
