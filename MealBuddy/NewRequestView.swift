import SwiftUI
import Firebase
import CoreLocation
import FirebaseAuth

struct NewRequestView: View {
    @State private var shortBlurb: String = ""
    @State private var selectedDate = Date()
    @State private var selectedMeal: String = "Breakfast"
    @State private var selectedCuisine: String = "American"
    @State private var selectedEvent: String = "Movie"
    @State private var diningOption: String = "Fast Food"
    @State private var isSubmitting = false
    @State private var submissionSuccess: Bool? = nil
    @State private var userEmail: String? = Auth.auth().currentUser?.email
    @State private var username: String? = Auth.auth().currentUser?.displayName
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var userAge: Int? = nil
    @State private var userGender: String? = nil

    private let locationManager = LocationManager()

    let mealOptions = ["Breakfast", "Lunch", "Dinner", "Coffee"]
    let cuisineOptions = ["American", "Mexican", "Italian", "Japanese", "Chinese", "Indian", "Thai", "Mediterranean"]
    let eventOptions = ["Movie", "Amusement Park", "Hiking", "Museum", "Shopping"]
    let diningOptions = ["Fast Food", "Sit-In"]

    var body: some View {
        NavigationView{
            VStack(spacing: 10) {
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
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#655745")))
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .tint(Color(hex: "#8B7355"))
                            .accentColor(Color(hex: "#8B7355"))
                    }
                }
                .padding(.horizontal, 15)

                // Event Type Picker
                HStack {
                    Text("Event Type")
                        .font(.headline)
                        .padding(.leading, 10)
                    Picker("Select Event", selection: $selectedEvent) {
                        ForEach(eventOptions, id: \ .self) { event in
                            Text(event).tag(event)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .styledInputField()
                    .accentColor(Color(hex: "#655745"))
                }

                // Cuisine Type Dropdown
                HStack {
                    Text("Cuisine Type")
                        .font(.headline)
                        .padding(.leading, 10)
                    Picker("Select Cuisine", selection: $selectedCuisine) {
                        ForEach(cuisineOptions, id: \ .self) { cuisine in
                            Text(cuisine).tag(cuisine)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .styledInputField()
                    .accentColor(Color(hex: "#655745"))
                }

                // Short Blurb
                TextField("Add a short blurb (e.g., 'Excited for a movie night!')", text: $shortBlurb)
                    .styledInputField()
                
                // Live Preview Section
                               Text("Preview of your request:")
                                   .frame(maxWidth: .infinity, alignment: .leading)
                                   .padding(.horizontal, 10)
                                   .foregroundColor(Color(hex: "#655745"))
                               VStack {
                                   Image(systemName: "person.circle.fill")
                                       .resizable()
                                       .scaledToFit()
                                       .frame(width: 50, height: 50)
                                       .foregroundColor(Color(hex: "#655745"))
                                   
                                   Text(username!)
                                       .font(.title)
                                       .foregroundColor(Color(hex: "#655745"))
                                   
                                   VStack(spacing: 20) {
                                       Text("Cuisine: " + selectedCuisine)
                                           .font(.headline)
                                           .foregroundColor(Color(hex: "#655745"))
                                           .padding(.horizontal, 10)
                                       Text("Event: " + selectedEvent)
                                           .font(.headline)
                                           .foregroundColor(Color(hex: "#655745"))
                                           .padding(.horizontal, 10)
                                       
                                    }
                                   
                                   Text(shortBlurb.isEmpty ? "\"Looking for company!\"" : "\"" + shortBlurb + "\"")
                                       .italic()
                                       .font(.headline)
                                       .foregroundColor(Color(hex: "#655745"))
                                       .padding(5)
                                   
                                   Text("x miles away")
                                       .font(.headline)
                                       .foregroundColor(Color(hex: "#655745"))
                                       
                               }
                               .frame(width: 280)
                               .padding()
                               .background(RoundedRectangle(cornerRadius: 15).fill(Color(UIColor.systemBrown).opacity(0.2)))

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
                        .foregroundColor(Color(hex: "#685643"))
                        .font(.headline)
                        .transition(.opacity)
                        .padding()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#EEE2D2"))
            .onAppear {
                locationManager.requestLocation { location in
                    self.userLocation = location
                }
                fetchUserDetails()
            }
            .navigationBarBackButtonHidden(true)
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
        
        if userLocation == nil {
                locationManager.requestLocation { location in
                    self.userLocation = location
                    self.finalizeRequestSubmission()
                }
            } else {
                finalizeRequestSubmission()
            }

        
    }
    
    func finalizeRequestSubmission() {
        let db = Firestore.firestore()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: selectedDate)

        let requestData: [String: Any] = [
            "blurb": shortBlurb,
            "date": formattedDate,
            "event": selectedEvent,
            "cuisine": selectedCuisine,
            "email": userEmail!,
            "username": username!,
            "age": userAge ?? NSNull(),
            "gender": userGender ?? NSNull(),
            "invitesSent": [] as NSArray,
            "timestamp": FieldValue.serverTimestamp(),
            "location": userLocation != nil ? [
                "latitude": userLocation!.latitude,
                "longitude": userLocation!.longitude
            ] : NSNull()
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
        selectedEvent = "Movie"
        selectedCuisine = "American"
    }
    
    func fetchUserDetails() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let userRef = Firestore.firestore().collection("users").document(userID)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.userAge = data?["age"] as? Int
                self.userGender = data?["gender"] as? String
            } else {
                print("User details not found")
            }
        }
    }
}

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
