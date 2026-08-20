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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Change Password")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                VStack(spacing: 0) {
                    if step == 1 {
                        formField(label: "Current Password") {
                            SecureField("Enter current password", text: $currentPassword)
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.never)
                                .accessibilityLabel("Current password")
                        }

                        Button(action: verifyCurrentPassword) {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Verify")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.brand)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Verify current password")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)

                    } else if step == 2 {
                        formField(label: "New Password") {
                            SecureField("Enter new password", text: $newPassword)
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.never)
                                .accessibilityLabel("New password")
                        }

                        formField(label: "Confirm New Password") {
                            SecureField("Re-enter new password", text: $confirmPassword)
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.never)
                                .accessibilityLabel("Confirm new password")
                        }

                        Button(action: updatePassword) {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Update Password")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.brand)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Update password")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )

                if step == 1 {
                    Button(action: sendResetPassword) {
                        Text("Forgot Password? Reset via Email")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .accessibilityLabel("Reset password via email")
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                }

                if !successMessage.isEmpty {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func formField(label: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            content()
                .font(.system(size: 15))
                .padding(12)
                .background(Color.white.opacity(0.07))
                .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
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
