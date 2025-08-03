import SwiftUI

struct ResetPasswordView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        Form {
            Section(header: Text("Reset Password").font(.title3).bold()) {
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)

                Button(action: {
                    // TODO: Implement password update logic
                }) {
                    Text("Update Password")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }
        }
        .background(Color.black)
        .scrollContentBackground(.hidden)
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}
