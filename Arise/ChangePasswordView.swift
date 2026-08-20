import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var step = 1
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var successMessage = ""
    
    let gradient = LinearGradient.brand
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Change Password")
                .font(.title.bold())
                .foregroundColor(.white)
                .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 20) {
                    if step == 1 {
                        SecureField("Current Password", text: $currentPassword)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .textInputAutocapitalization(.never)
                            .accessibilityLabel("Current password")
                        
                        Button(action: verifyCurrentPassword) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Verify")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(gradient)
                                    .cornerRadius(12)
                            }
                        }
                        .accessibilityLabel("Verify current password")
                        
                        // --- RESET PASSWORD OPTION ---
                        Button(action: sendResetPassword) {
                            Text("Forgot Password? Reset via Email")
                                .foregroundColor(.blue)
                                .font(.footnote)
                        }
                        .accessibilityLabel("Reset password via email")
                        .padding(.top, 10)
                    } else if step == 2 {
                        SecureField("New Password", text: $newPassword)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .textInputAutocapitalization(.never)
                            .accessibilityLabel("New password")
                        
                        SecureField("Confirm New Password", text: $confirmPassword)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .textInputAutocapitalization(.never)
                            .accessibilityLabel("Confirm new password")
                        
                        Button(action: updatePassword) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Update Password")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(gradient)
                                    .cornerRadius(12)
                            }
                        }
                        .accessibilityLabel("Update password")
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
    
    private func verifyCurrentPassword() {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "User not found."
            return
        }
        
        isLoading = true
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { result, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if error != nil {
                    self.errorMessage = "Incorrect password. Try again."
                } else {
                    self.step = 2
                    self.errorMessage = ""
                }
            }
        }
    }
    
    private func updatePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        
        isLoading = true
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to update password: \(error.localizedDescription)"
                } else {
                    self.successMessage = "Password updated successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.dismiss()
                    }
                }
            }
        }
    }
    
    private func sendResetPassword() {
        guard let email = Auth.auth().currentUser?.email else {
            errorMessage = "No email associated with this account."
            return
        }
        
        isLoading = true
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to send reset email: \(error.localizedDescription)"
                } else {
                    self.successMessage = "Password reset email sent! Check your inbox."
                }
            }
        }
    }
}
