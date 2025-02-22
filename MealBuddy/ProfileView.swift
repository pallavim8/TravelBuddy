
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @State private var selectedDietaryRestrictions: [String] = []
    @State private var priceRange: Double = 1
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var isSaved: Bool = false
    @State private var isChanged: Bool = false
    @State private var preferredRadius: Int = 10
    @State private var initialPreferredRadius: Int = 0
    @State private var initialUsername: String = ""
    @State private var initialDietaryRestrictions: [String] = []
    @State private var initialPriceRange: Double = 1
    @State private var navigateToHome = false

    
    let db = Firestore.firestore()
    @State private var userID = Auth.auth().currentUser?.uid ?? "unknown"
    
    let dietaryOptions = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Halal", "Kosher"]
    
    let radiusOptions = [5, 10, 15, 20]

    
    var body: some View {
        
        NavigationView{
            
            VStack {
                NavigationLink(destination: HomeView(), isActive: $navigateToHome) {
                    EmptyView()
                }
                // Username TextField for editing
                Text("Edit Profile").font(.title).padding()
                Text("Username").font(.headline)
                TextField("Enter your username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: username) { _ in
                        checkForChanges()
                    }
                
                Text("Select your Dietary Restrictions")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(dietaryOptions, id: \.self) { option in
                    Toggle(option, isOn: Binding(
                        get: { selectedDietaryRestrictions.contains(option) },
                        set: { isSelected in
                            if isSelected {
                                
                                if !selectedDietaryRestrictions.contains(option) {
                                    selectedDietaryRestrictions.append(option)
                                }
                            } else {
                                selectedDietaryRestrictions.removeAll { $0 == option }
                            }
                            checkForChanges()
                        }
                    ))
                    .padding(.vertical, 4)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preferred Radius (miles)")
                        .font(.headline)
                    Picker("Preferred Radius", selection: $preferredRadius) {
                        ForEach(radiusOptions, id: \.self) { radius in
                            Text("\(radius) miles").tag(radius)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .onChange(of: preferredRadius) { _ in checkForChanges() }
                }
                .padding(.horizontal)
                
                Text("Price Range (\(priceRangeText()))")
                    .font(.headline)
                    .padding(.top)
                
                Slider(value: $priceRange, in: 1...3, step: 1)
                    .padding(.horizontal)
                    .onChange(of: priceRange) { _ in
                        checkForChanges()
                    }
                
                Button("Save Preferences") {
                    
                    let dietaryRestrictions = selectedDietaryRestrictions.joined(separator: ", ")
                    
                    
                    db.collection("users").document(userID).setData([
                        "username": username,
                        "email": email,
                        "dietary_restrictions": dietaryRestrictions,
                        "price_range": priceRangeText(),
                        "preffered_radius": preferredRadius
                    ], merge: true) { error in
                        if let error = error {
                            print("Error updating user data: \(error.localizedDescription)")
                        } else {
                            print("User data successfully updated")
                            isSaved = true
                            isChanged = false
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isSaved = false
                            }
                        }
                    }
                }
                .padding()
                .background(isChanged ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(!isChanged)
                
                if isSaved {
                    Text("Preferences Saved!")
                        .foregroundColor(.green)
                        .font(.headline)
                        .transition(.opacity)
                        .padding()
                }
            }
            .padding()
            .onAppear {
                fetchUserData()
            }.navigationBarItems(leading: Button(action: {
                navigateToHome = true
            }) {
                HStack {
                    Image(systemName: "chevron.left") // Default back button icon
                        .foregroundColor(.blue) // Matches default back button color
                    Text("Home")
                        .foregroundColor(.blue)
                }
            })
        }
        .navigationBarBackButtonHidden(true)
            
    }
    
    func priceRangeText() -> String {
        switch priceRange {
        case 1:
            return "$"
        case 2:
            return "$$"
        case 3:
            return "$$$"
        default:
            return "$"
        }
    }
    
    func fetchUserData() {
        if let user = Auth.auth().currentUser {
            userID = user.uid
            username = user.displayName ?? ""
            email = user.email ?? ""
            
            db.collection("users").document(userID).getDocument { document, error in
                if let document = document, document.exists {
                    let data = document.data()
                    selectedDietaryRestrictions = (data?["dietary_restrictions"] as? String)?
                        .split(separator: ",")
                        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
                    priceRange = priceRangeFromText(data?["price_range"] as? String ?? "$")
                    preferredRadius = data?["preferred_radius"] as? Int ?? 10
                    
                    initialUsername = username
                    initialDietaryRestrictions = selectedDietaryRestrictions
                    initialPriceRange = priceRange
                    initialPreferredRadius = preferredRadius
                } else {
                 
                    createBlankUserDocument()
                }
            }
        }
    }
    
    func createBlankUserDocument() {
        db.collection("users").document(userID).setData([
            "username": "",
            "email": email,
            "dietary_restrictions": "",
            "price_range": "$",
            "preferred_radius": preferredRadius
        ]) { error in
            if let error = error {
                print("Error creating blank user document: \(error.localizedDescription)")
            } else {
                print("Blank user document created successfully.")
            }
        }
    }

    func priceRangeFromText(_ text: String) -> Double {
        switch text {
        case "$$$":
            return 3
        case "$$":
            return 2
        case "$":
            return 1
        default:
            return 1
        }
    }
    
    func checkForChanges() {
        isChanged = (username != initialUsername ||
                     selectedDietaryRestrictions != initialDietaryRestrictions ||
                     priceRange != initialPriceRange || preferredRadius != initialPreferredRadius)
    }
}

#Preview {
    ProfileView()
}
