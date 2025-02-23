import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @State private var selectedDietaryRestrictions: [String] = []
    @State private var priceRange: Double = 1
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var gender: String = ""
    @State private var age: String = ""
    @State private var isSaved: Bool = false
    @State private var isChanged: Bool = false
    @State private var preferredRadius: Int = 10
    @State private var initialPreferredRadius: Int = 0
    @State private var initialUsername: String = ""
    @State private var initialDietaryRestrictions: [String] = []
    @State private var initialPriceRange: Double = 1
    @State private var initialGender: String = ""
    @State private var initialAge: String = ""
    @State private var navigateToHome = false

    let db = Firestore.firestore()
    @State private var userID = Auth.auth().currentUser?.uid ?? "unknown"

    let dietaryOptions = ["Vegetarian", "Vegan", "Dairy-Free", "Halal", "Peanut Allergy"]
    let radiusOptions = [5, 10, 15, 20]
    let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: HomeView(), isActive: $navigateToHome) {
                    EmptyView()
                }
                
                Text("Edit \(username)'s Profile").font(.largeTitle).padding()
                
                HStack{
                    Text("Age").font(.headline).padding(.top)
                    TextField("Enter your age", text: $age)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(hex: "#DBC9B1"))
                        .cornerRadius(30)
                        .onChange(of: age) { _ in checkForChanges() }

                    Text("Gender").font(.headline).padding(.top)
                    Picker("Select Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color(hex: "#DBC9B1"))
                    .cornerRadius(30)
                    .onChange(of: gender) { _ in checkForChanges() }
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
                    .tint(Color(hex: "#685643"))
                    .padding(.horizontal, 10)
                }

                // Preferred Radius
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preferred Radius (miles)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    ZStack {
                        Picker("Preferred Radius", selection: $preferredRadius) {
                            ForEach(radiusOptions, id: \.self) { radius in
                                Text("\(radius) miles").tag(radius)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .accentColor(Color(hex: "#685643"))
                        .frame(maxWidth: .infinity)
                        .onChange(of: preferredRadius) { _ in checkForChanges()}
                    }
                }
                .padding(.horizontal)

                // Price Range
                Text("Price Range (\(priceRangeText()))")
                    .font(.headline)
                
                Slider(value: $priceRange, in: 1...3, step: 1)
                    .padding(.horizontal)
                    .tint(Color(hex: "#685643"))
                    .onChange(of: priceRange) { _ in checkForChanges() }

                // Save Button
                Button("Save Preferences") {
                    let dietaryRestrictions = selectedDietaryRestrictions.joined(separator: ", ")
                    
                    db.collection("users").document(userID).setData([
                        "username": username,
                        "email": email,
                        "gender": gender,
                        "age": Int(age) ?? 0,
                        "dietary_restrictions": dietaryRestrictions,
                        "price_range": priceRangeText(),
                        "preferred_radius": preferredRadius
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
                .background(isChanged ? Color(hex: "#685643") : Color(hex: "#c4b5a3"))
                .foregroundColor(.white)
                .cornerRadius(30)
                .disabled(!isChanged)

                if isSaved {
                    Text("Preferences Saved!")
                        .foregroundColor(Color(hex: "#685643"))
                        .font(.headline)
                        .transition(.opacity)
                        .padding()
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#EEE3D2"))
            .onAppear {
                fetchUserData()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    func priceRangeText() -> String {
        switch priceRange {
        case 1: return "$"
        case 2: return "$$"
        case 3: return "$$$"
        default: return "$"
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
                    gender = data?["gender"] as? String ?? ""
                    age = data?["age"] as? String ?? ""

                    initialUsername = username
                    initialDietaryRestrictions = selectedDietaryRestrictions
                    initialPriceRange = priceRange
                    initialPreferredRadius = preferredRadius
                    initialGender = gender
                    initialAge = age
                } else {
                    createBlankUserDocument()
                }
            }
        }
    }

    func checkForChanges() {
        isChanged = (username != initialUsername ||
                     selectedDietaryRestrictions != initialDietaryRestrictions ||
                     priceRange != initialPriceRange ||
                     preferredRadius != initialPreferredRadius ||
                     gender != initialGender ||
                     age != initialAge)
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

}


#Preview {
    ProfileView()
}
