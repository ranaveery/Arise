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
    
    let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 84/255, green: 0/255, blue: 232/255),
            Color(red: 236/255, green: 71/255, blue: 1/255)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
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
                            .autocapitalization(.none)
                        
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
                    } else if step == 2 {
                        SecureField("New Password", text: $newPassword)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                        
                        SecureField("Confirm New Password", text: $confirmPassword)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                        
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
            isLoading = false
            if let error = error {
                errorMessage = "Incorrect password. Try again."
                print("Reauth error: \(error.localizedDescription)")
            } else {
                step = 2
                errorMessage = ""
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
            isLoading = false
            if let error = error {
                errorMessage = "Failed to update password: \(error.localizedDescription)"
            } else {
                successMessage = "Password updated successfully!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }
}
