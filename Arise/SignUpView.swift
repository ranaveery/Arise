import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct SignUpView: View {
    @Binding var isUserLoggedIn: Bool
    @Binding var showLogin: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {

            Image("logo_arise")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.top, 10)

            Text("Get Started")
                .font(.title.bold())
                .foregroundColor(.white)

            VStack(spacing: 16) {
                TextField("Name", text: $name)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .onChange(of: name) { oldValue, newValue in
                        name = sanitizeName(newValue)
                    }

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
                        .padding(.top, -4)
                }
            }

            Button(action: registerUser) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(25)
                } else {
                    Text("Create Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.brand)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }

            HStack(spacing: 4) {
                Text("Have an account?")
                    .foregroundColor(.white)
                Button(action: {
                    withAnimation { dismiss() }
                }) {
                    Text("Log in")
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
    
    private func registerUser() {
        isLoading = true
        errorMessage = ""

        guard !name.isEmpty else {
            errorMessage = "Name is required."
            isLoading = false
            return
        }
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Invalid email format."
            isLoading = false
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            isLoading = false
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = result?.user {
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(user.uid)

                let basicData: [String: Any] = [
                    "uid": user.uid,
                    "name": sanitizeName(name),
                    "email": email
                ]

                userRef.setData(basicData, merge: true) { _ in
                    DispatchQueue.main.async {
                        isUserLoggedIn = true
                    }
                }
            }
        }
    }

}
