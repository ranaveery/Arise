import SwiftUI
import FirebaseAuth


struct LoginView: View {
    @Binding var isUserLoggedIn: Bool
    @Binding var showLogin: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss


    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            Image("logo_arise")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.top, 10)

            Text("Time to Arise")
                .font(.title.bold())
                .foregroundColor(.white)

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $password)
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
                        .padding(.horizontal, 8)
                }
            }

            Button(action: loginUser) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(25)
                } else {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.brand)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }

            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundColor(.white)
                Button(action: {
                    withAnimation {
                        dismiss()
                    }
                }) {
                    Text("Sign up")
                        .foregroundColor(Color.blue)
                        .fontWeight(.semibold)
                }
            }

            HStack {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                Text("OR")
                    .foregroundColor(.gray)
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
            }
            .padding(.vertical, 10)

            Button(action: {
                withAnimation {
                    dismiss()
                }
            }) {
                HStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)

                    Text("Sign in with a provider")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.05))
                .foregroundColor(.white)
                .cornerRadius(30)
            }

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }

    private func loginUser() {
        isLoading = true
        errorMessage = ""
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                let ns = error as NSError
                switch AuthErrorCode(rawValue: ns.code) {
                case .wrongPassword, .invalidEmail, .userNotFound, .invalidCredential:
                    errorMessage = "Email or password incorrect. Try again."
                case .networkError:
                    errorMessage = "Network error. Check your connection and try again."
                default:
                    errorMessage = error.localizedDescription
                }
            }
            else {
                isUserLoggedIn = true
            }
        }
    }

}
