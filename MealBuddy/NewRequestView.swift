//
//  NewRequestView.swift
//  MealBuddy
//
//  Created by Chinju on 2/22/25.
//


import SwiftUI
import Firebase
import CoreLocation
import FirebaseAuth

struct NewRequestView: View {
    @State private var shortBlurb: String = ""
    @State private var selectedDate = Date()
    @State private var selectedMeal: String = "Breakfast"
    @State private var selectedCuisine: String = "American"
    @State private var diningOption: String = "Fast Food"
    @State private var isSubmitting = false
    @State private var submissionSuccess: Bool? = nil
    @State private var userEmail: String? = Auth.auth().currentUser?.email
    @State private var username: String? = Auth.auth().currentUser?.displayName
    @State private var userLocation: CLLocationCoordinate2D?

    private let locationManager = LocationManager()

    let mealOptions = ["Breakfast", "Lunch", "Dinner", "Coffee"]
    let cuisineOptions = ["American", "Mexican", "Italian", "Japanese", "Chinese", "Indian", "Thai", "Mediterranean"]
    let diningOptions = ["Fast Food", "Sit-In"]

    var body: some View {
        NavigationView{
            VStack(spacing: 20) {
                HStack(spacing: 0) {
                    Image("forkKnife")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                    
                    Text("MEALBUDDY")
                        .font(.largeTitle).bold()
                        .foregroundColor(.black)
                    Spacer()
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color(hex: "#655745"))
                    }
                    
                }
                Text("Create a New Request")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "#655745"), lineWidth: 2)
                            .frame(height: 45)
                        HStack{
                            Text("Select Date: ").padding(.horizontal, 10)
                            Spacer()
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#655745"))) // Existing background
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .tint(Color(hex: "#8B7355"))
                                .accentColor(Color(hex: "#8B7355"))
                        }
                    }
                    .padding(.horizontal, 15)

                // Meal Type Picker
                
                Picker("Select Meal", selection: $selectedMeal) {
                    ForEach(mealOptions, id: \.self) { meal in
                        Text(meal).tag(meal)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Cuisine Type Dropdown
                VStack(alignment: .leading) {
                    Text("Cuisine Type")
                        .font(.headline)
                        .padding(.leading, 10)
                    Picker("Select Cuisine", selection: $selectedCuisine) {
                        ForEach(cuisineOptions, id: \.self) { cuisine in
                            Text(cuisine).tag(cuisine)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // Dropdown menu
                    .styledInputField()
                }
                
                // Fast Food or Sit-In Picker
                Picker("Dining Preference", selection: $diningOption) {
                    ForEach(diningOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Short Blurb at the bottom
                TextField("Add a short blurb (e.g., 'Craving sushi in town!')", text: $shortBlurb)
                    .styledInputField()
                
                // Live Preview Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("🔍 Request Preview")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("**Date:** \(formattedDate(selectedDate))")
                    Text("**Meal:** \(selectedMeal)")
                    Text("**Cuisine:** \(selectedCuisine)")
                    Text("**Dining Preference:** \(diningOption)")
                    Text("**Blurb:** \(shortBlurb.isEmpty ? "No blurb added" : shortBlurb)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color(.systemGray6)))
                .padding(.horizontal)
                
                // Submit Button
                Button(action: submitRequest) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Submit Request")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(RoundedRectangle(cornerRadius: 25).fill(Color.brown))
                            .padding(.horizontal)
                    }
                }
                .disabled(isSubmitting)
                
                // Submission Feedback
                if let success = submissionSuccess {
                    Text(success ? "Request submitted successfully!" : "Failed to submit request.")
                        .foregroundColor(success ? .green : .red)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#EEE2D2"))
            .onAppear {
                locationManager.requestLocation { location in
                    self.userLocation = location
                }
            }
        }
    }

    // Function to Submit Data to Firebase
    func submitRequest() {
        isSubmitting = true
        let db = Firestore.firestore()

        guard let userEmail = userEmail else {
            print("Error: No logged-in user found")
            submissionSuccess = false
            isSubmitting = false
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // Ensure consistent format
        let formattedDate = dateFormatter.string(from: selectedDate)

        let requestData: [String: Any] = [
            "blurb": shortBlurb,
            "date": formattedDate,  // Store date as a string
            "meal": selectedMeal,
            "cuisine": selectedCuisine,
            "diningOption": diningOption,
            "email": userEmail,
            "username": username,
            "timestamp": FieldValue.serverTimestamp(),
            "location": userLocation != nil ? [
                "latitude": userLocation!.latitude,
                "longitude": userLocation!.longitude
            ] : NSNull(),
            "invitesSent": []
        ]
        
        db.collection("requests").addDocument(data: requestData) { error in
            isSubmitting = false
            if let error = error {
                print("Error adding request: \(error)")
                submissionSuccess = false
            } else {
                submissionSuccess = true
                clearForm()
            }
        }
    }
    
    // Function to Reset Form
    func clearForm() {
        shortBlurb = ""
        selectedDate = Date()
        selectedMeal = "Breakfast"
        selectedCuisine = "American"
        diningOption = "Fast Food"
    }

    // Format Date
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// SwiftUI Modifier for Input Fields
extension View {
    func styledInputField() -> some View {
        self
            .padding()
            .frame(height: 50)
            .background(RoundedRectangle(cornerRadius: 25).stroke(Color.black, lineWidth: 2))
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.black)
            .padding(.horizontal)
    }
}

// 🔥 Custom Location Manager to Get User's GPS Coordinates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var completion: ((CLLocationCoordinate2D?) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // Ask for permission
    }

    func requestLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        self.completion = completion
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            completion?(location.coordinate)
        } else {
            completion?(nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error)")
        completion?(nil)
    }
}


#Preview {
    NewRequestView()
}

