import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var error: String?
    @State private var success = false

    var body: some View {
        Form {
            Section(header: Text("Reset Password").font(.title3).bold()) {
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if success {
                    Text("Password updated successfully.")
                        .foregroundColor(.green)
                        .font(.caption)
                }

                Button(action: updatePassword) {
                    Text("Update Password")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
                .disabled(newPassword.isEmpty || confirmPassword.isEmpty)
            }
        }
        .background(Color.black)
        .scrollContentBackground(.hidden)
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func updatePassword() {
        guard newPassword.count >= 6 else {
            error = "Password must be at least 6 characters."
            return
        }
        guard newPassword == confirmPassword else {
            error = "Passwords do not match."
            return
        }
        error = nil
        Auth.auth().currentUser?.updatePassword(to: newPassword) { err in
            if let err = err {
                error = err.localizedDescription
            } else {
                success = true
                newPassword = ""
                confirmPassword = ""
            }
        }
    }
}
