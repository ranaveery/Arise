import SwiftUI
import FirebaseAuth
import GoogleSignIn
import Firebase

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
                .frame(width: 130, height: 130)
                .padding(.top, 10)

            Text("Time to Arise")
                .font(.largeTitle.bold())
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

            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundColor(.white)
                Button(action: {
                    withAnimation {
                        dismiss()  // Takes user back to LandingView
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

            Button(action: signInWithGoogle) {
                HStack {
                    Image("google_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)

                    Text("Continue with Google")
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
                print("Login error: \(error.localizedDescription)")
                errorMessage = "Email or password incorrect. Try again"
            }
            else {
                isUserLoggedIn = true
            }
        }
    }

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("No rootViewController found")
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: nil,
            nonce: nil
        ) { signInResult, error in
            if let error = error {
                print("Google Sign-In failed:", error.localizedDescription)
                return
            }

            guard let user = signInResult?.user,
                  let idTokenObj = user.idToken else {
                print("Missing user or ID token")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idTokenObj.tokenString,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase login failed:", error.localizedDescription)
                    return
                }

                guard let firebaseUser = result?.user else { return }

                let fullName = user.profile?.name ?? "No Name"
                let email = user.profile?.email ?? "No Email"
                let uid = firebaseUser.uid

                let db = Firestore.firestore()
                let userRef = db.collection("users").document(uid)
                userRef.setData([
                    "name": fullName,
                    "email": email,
                    "uid": uid
                ], merge: true) { err in
                    if let err = err {
                        print("Error saving user to Firestore: \(err.localizedDescription)")
                    } else {
                        print("User saved to Firestore")
                    }
                }

                UserDefaults.standard.set(fullName, forKey: "userName")
                UserDefaults.standard.set(email, forKey: "userEmail")

                DispatchQueue.main.async {
                    isUserLoggedIn = true
                }
            }
        }
    }
}
