import SwiftUI
import FirebaseAuth


struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var isLoggedIn = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var navigateToHome = false
    @State private var navigateToProfile = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: 0) {
                    Image("forkKnife")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                    
                    Text("MEALBUDDY")
                        .font(.largeTitle).bold()
                        .foregroundColor(.black)
                }
                if isSignUp {
                    
                    RoundedRectangle(cornerRadius: 30)
                                       .fill(Color(hex: "#D8CAB4"))
                                       .frame(width: 360, height: 470)
                                       .overlay(
                                        VStack{
                                            Text(isSignUp ? "Sign Up" : "Login")
                                                .font(.largeTitle)
                                                .bold()
                                                .padding()
                                                Text("Username").frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                                                TextField("Enter your username", text: $name)
                                                    .padding(12)
                                                    .background(Color(hex: "#D8CAB4"))
                                                    .cornerRadius(50) // Background rounded corners
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 50) // Rounded border
                                                            .stroke(Color(hex: "#655745"), lineWidth: 2)
                                                    )
                                                    .autocapitalization(.none)
                                                    .keyboardType(.emailAddress)
                                                    .padding(.horizontal, 10)
                                                    .padding(.bottom, 20)
                                            Text("Email").frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                                            TextField("Enter your email", text: $email)
                                                .padding(12)
                                                .background(Color(hex: "#D8CAB4"))
                                                .cornerRadius(50) // Background rounded corners
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 50) // Rounded border
                                                        .stroke(Color(hex: "#655745"), lineWidth: 2)
                                                )
                                                .autocapitalization(.none)
                                                .keyboardType(.emailAddress)
                                                .padding(.horizontal, 10)
                                                .padding(.bottom, 20)
                                            Text("Password").frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                                            SecureField("Enter your password", text: $password)
                                                .padding(12)
                                                .background(Color(hex: "#D8CAB4"))
                                                .cornerRadius(50) // Background rounded corners
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 50) // Rounded border
                                                        .stroke(Color(hex: "#655745"), lineWidth: 2)
                                                )
                                                .autocapitalization(.none)
                                                .keyboardType(.emailAddress)
                                                .padding(.horizontal, 10)
                                            Button(action: {
                                                if isSignUp {
                                                    signUpUser()
                                                } else {
                                                    loginUser()
                                                }
                                            }) {
                                                Text(isSignUp ? "Sign Up" : "Login")
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(isButtonDisabled() ? Color(hex: "#655745"): Color(hex: "#655745"))
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(Color(hex: "#F6F3EC"))
                                                    .cornerRadius(30)
                                                    .opacity(isButtonDisabled() ? 0.6 : 1.0)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.top, 20)
                                            .padding(.bottom, 20)
                                            .alert(isPresented: $showAlert) {
                                                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                                            }
                                            .disabled(isButtonDisabled())
                                            
                                        }
                                       )
                } else{
                    
                    RoundedRectangle(cornerRadius: 30)
                                       .fill(Color(hex: "#D8CAB4"))
                                       .frame(width: 360, height: 370)
                                       .overlay(
                                        VStack{
                                            Text(isSignUp ? "Sign Up" : "Login")
                                                .font(.largeTitle)
                                                .bold()
                                                .padding()
                                            Text("Email").frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                                            TextField("Enter your email", text: $email)
                                                .padding(12)
                                                .background(Color(hex: "#D8CAB4"))
                                                .cornerRadius(50) // Background rounded corners
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 50) // Rounded border
                                                        .stroke(Color(hex: "#655745"), lineWidth: 2)
                                                )
                                                .autocapitalization(.none)
                                                .keyboardType(.emailAddress)
                                                .padding(.horizontal, 10)
                                                .padding(.bottom, 20)
                                            Text("Password").frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                                            SecureField("Enter your password", text: $password)
                                                .padding(12)
                                                .background(Color(hex: "#D8CAB4"))
                                                .cornerRadius(50) // Background rounded corners
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 50) // Rounded border
                                                        .stroke(Color(hex: "#655745"), lineWidth: 2)
                                                )
                                                .autocapitalization(.none)
                                                .keyboardType(.emailAddress)
                                                .padding(.horizontal, 10)
                                            Button(action: {
                                                if isSignUp {
                                                    signUpUser()
                                                } else {
                                                    loginUser()
                                                }
                                            }) {
                                                Text(isSignUp ? "Sign Up" : "Login")
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(isButtonDisabled() ? Color(hex: "#655745"): Color(hex: "#655745"))
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(Color(hex: "#F6F3EC"))
                                                    .cornerRadius(30)
                                                    .opacity(isButtonDisabled() ? 0.6 : 1.0)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.top, 20)
                                            .padding(.bottom, 20)
                                            .alert(isPresented: $showAlert) {
                                                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                                            }
                                            .disabled(isButtonDisabled())
                                            
                                        }
                                       )
                }
                NavigationLink(destination: MainTabView(startingTab: 0), isActive: $navigateToHome) {
                    EmptyView()
                }
                NavigationLink(destination: MainTabView(startingTab: 3), isActive: $navigateToProfile) {
                    EmptyView()
                }
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "Already have an account? " : "Don't have an account? ")
                        .foregroundColor(Color(hex: "#655745")) +
                    Text(isSignUp ? "Log in" : "Sign up")
                        .foregroundColor(Color(hex: "#CD7741"))
                        .bold()
                }
                .padding(20)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#EEE2D2"))
            
        }.navigationBarBackButtonHidden(true)
        
    }
    
    func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = "Login failed: \(error.localizedDescription)"
                showAlert = true
                return
            }
            navigateToHome = true
        }
    }
    
    func signUpUser() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = "Sign up failed: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            // Update the user's profile with the name
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = name
            changeRequest?.commitChanges { error in
                if let error = error {
                    alertMessage = "Failed to update profile: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    navigateToProfile = true
                }
            }
        }
    }
    
    // Check if the button should be disabled
    func isButtonDisabled() -> Bool {
        if isSignUp {
            return email.isEmpty || password.count < 6 || name.isEmpty
        } else {
            return email.isEmpty || password.count < 6
        }
    }
}

#Preview {
    AuthView()
}
