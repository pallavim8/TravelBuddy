import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
struct MainTabView: View {
    @State private var selectedTab: Int

    init(startingTab: Int = 0) {
        _selectedTab = State(initialValue: startingTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            MyRequestsView()
                .tabItem {
                    Image(systemName: "envelope.fill")
                    Text("Your Requests")
                }
                .tag(1)

            ChatListView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
            NewRequestView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("New Request")
                }
                .tag(4)
        }
        .accentColor(Color(hex: "#CD7741"))
        .navigationBarBackButtonHidden(true)
        .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView() // Ensures the back button is completely removed
                }
            }
    }
        
}

struct FilterSheetView: View {
    @Binding var selectedCuisine: String?
    @Binding var selectedEvent: String?
    @Binding var selectedGender: String?
    @Binding var selectedAgeRange: String?
    @Binding var selectedDate: Date
    var onApply: () -> Void

    let cuisineOptions = ["Any", "American", "Mexican", "Italian", "Japanese", "Chinese", "Indian", "Thai", "Mediterranean"]
    let eventOptions = ["Any", "Movie", "Amusement Park", "Hiking", "Museum", "Shopping"]
    let genderOptions = ["Any", "Male", "Female", "Non-binary"]
    let ageRanges = ["Any", "18-25", "26-35", "36-50", "50+"]
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Meal Preferences")) {
                        Picker("Cuisine", selection: Binding(
                            get: { selectedCuisine ?? "Any" },
                            set: { selectedCuisine = $0 == "Any" ? nil : $0 }
                        )) {
                            ForEach(cuisineOptions, id: \.self) { Text($0).tag($0) }
                        }
                        
                        Picker("Event", selection: Binding(
                            get: { selectedEvent ?? "Any" },
                            set: { selectedEvent = $0 == "Any" ? nil : $0 }
                        )) {
                            ForEach(eventOptions, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    
                    Section(header: Text("Demographic Preferences")) {
                        Picker("Gender", selection: Binding(
                            get: { selectedGender ?? "Any" },
                            set: { selectedGender = $0 == "Any" ? nil : $0 }
                        )) {
                            ForEach(genderOptions, id: \.self) { Text($0).tag($0) }
                        }
                        
                        Picker("Age Range", selection: Binding(
                            get: { selectedAgeRange ?? "Any" },
                            set: { selectedAgeRange = $0 == "Any" ? nil : $0 }
                        )) {
                            ForEach(ageRanges, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    
                    Section(header: Text("Date")) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    }
                }
                
                HStack {
                    Spacer()
                    Button(action: onApply) {
                        Text("Apply Filters")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#CD7741"))
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Filter Requests", displayMode: .inline)
        }
    }
}

struct HomeView: View {
    @State private var userEmail: String = ""
    @State private var userName: String = ""
    @State private var isLoggedOut = false
    @State private var connectionRequests: [ConnectionRequest] = []
    @State private var isLoading: Bool = true
    @State private var selectedDate = Date()
    @State private var selectedCuisine: String? = nil
    @State private var selectedEvent: String? = nil
    @State private var selectedAgeRange: String? = nil
    @State private var selectedGender: String? = nil
    @State private var currentIndex = 0
    @State private var userLocation: CLLocation?
    @State private var showFilterSheet = false
    
    
    let cuisineOptions = ["American", "Mexican", "Italian", "Japanese", "Chinese", "Indian", "Thai", "Mediterranean"]
    let eventOptions = ["Movie", "Amusement Park", "Hiking", "Museum", "Shopping"]
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Image("forkKnife")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                    
                    Text("MEALBUDDY")
                        .font(.largeTitle).bold()
                        .foregroundColor(.black)
                    Spacer()
                    
                    NavigationLink(destination: MainTabView(startingTab: 3)) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color(hex: "#655745"))
                    }
                    
                }
                .padding(.horizontal, 15)
                .padding(.top, 100)
                Text("Welcome, \(userName)!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 15)
                
                
                
                HStack {
                    
                    Text("Filter")
                        .font(.headline).bold()
                        .foregroundColor(.black)
                    Spacer()
                    
                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .padding()
                            .background(Circle().fill(Color(UIColor.systemBrown).opacity(0.2)))
                            .foregroundColor(.brown)
                    }
                    
                    
                }
                .padding(.horizontal)
                
                // Nearby Requests
                Text("Nearby Requests")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .fontWeight(.heavy)
                
                if isLoading {
                    ProgressView("Loading requests...")
                        .padding()
                } else if connectionRequests.isEmpty {
                    VStack{
                        Text("No requests found? ")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Create a new request or update your location preferences!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    .padding()
                    
                    Spacer(minLength: 250)
                    
                } else {
                    HStack {
                        Button(action: {
                            if currentIndex > 0 { currentIndex -= 1 }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.largeTitle)
                                .foregroundColor(.brown)
                        }
                        Spacer()
                        RequestCard(request: connectionRequests[currentIndex], userLocation: userLocation)
                        
                        //                            Spacer()
                        Button(action: {
                            if currentIndex < connectionRequests.count - 1 { currentIndex += 1 }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.largeTitle)
                                .foregroundColor(.brown)
                        }
                    }
                    .padding()
                }
                
                VStack(alignment: .leading) {
                    Text("Create A New Request")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("Don’t feel like eating alone? Make a new request to match with people in your area")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading)
                        
                        Spacer()
                        
                        NavigationLink(destination: MainTabView(startingTab: 4)) {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.brown)
                                .background(Circle().fill(Color(UIColor.systemBrown).opacity(0.2)))
                        }
                    }
                    
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 30).fill(Color(UIColor.systemBrown).opacity(0.2))) // Rounded rectangle around the whole section
                .padding(.bottom, 120) // Adjust bottom padding for better spacing between buttons
                
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#EEE2D2"))
            .onAppear {
                fetchUser()
                fetchUserLocation()
                fetchConnectionRequests()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView() // Ensures the back button is completely removed
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(
                selectedCuisine: $selectedCuisine,
                selectedEvent: $selectedEvent,
                selectedGender: $selectedGender,
                selectedAgeRange: $selectedAgeRange,
                selectedDate: $selectedDate,
                onApply: {
                    showFilterSheet = false
                    fetchConnectionRequests() // Fetch after applying filters
                }
            )
        }
    }
    
    
    func fetchUserLocation() {
        if CLLocationManager.locationServicesEnabled() {
            let locationManager = CLLocationManager()
            locationManager.requestWhenInUseAuthorization()
            
            if let location = locationManager.location {
                userLocation = location
                updateLocationInFirestore(location: location)
            }
        }
    }
    
    func updateLocationInFirestore(location: CLLocation) {
        let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        db.collection("users").document(Auth.auth().currentUser?.uid ?? "unknown").updateData([
            "location": geoPoint
        ]) { error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
            } else {
                print("User location updated successfully.")
            }
        }
    }
    
    
    func fetchUser() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? "User"
            userName = user.displayName ?? "User"
        }
    }
    
    func fetchConnectionRequests() {
        isLoading = true
        print("Fetching connection requests...")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: selectedDate)

        print("Selected date: \(formattedDate)")

        guard let userLocation = userLocation else {
            print("User location not available")
            isLoading = false
            return
        }

        let userRef = db.collection("users").document(Auth.auth().currentUser?.uid ?? "unknown")

        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                isLoading = false
                return
            }

            guard let document = document, document.exists else {
                print("User document does not exist")
                isLoading = false
                return
            }

            let preferredRadius = document.data()?["preferred_radius"] as? Int ?? 10
            print("Preferred radius: \(preferredRadius) miles")

            var query: Query = db.collection("requests")

            // Apply filters **only if "Any" is not selected**
            if let cuisine = selectedCuisine, cuisine != "Any" {
                query = query.whereField("cuisine", isEqualTo: cuisine)
                print("Filtering by cuisine: \(cuisine)")
            }
            if let event = selectedEvent, event != "Any" {
                query = query.whereField("event", isEqualTo: event)
                print("Filtering by event: \(event)")
            }
            if let gender = selectedGender, gender != "Any" {
                query = query.whereField("gender", isEqualTo: gender)
                print("Filtering by gender: \(gender)")
            }

            // Apply date filter
            query = query.whereField("date", isEqualTo: formattedDate)
            print("Filtering by date: \(formattedDate)")

            // Now, fetch documents from Firestore
            query.getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    print("Error fetching requests: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No matching requests found")
                    connectionRequests = []
                    return
                }

                print("Found \(documents.count) request(s) before filtering by location")

                connectionRequests = documents.compactMap { document in
                    var request: ConnectionRequest?
                    do {
                        request = try document.data(as: ConnectionRequest.self)
                    } catch {
                        print("Error decoding request: \(error)")
                        return nil
                    }

                    // Handle age range filtering
                    if let requestAge = request?.age, let validRequest = request {
                        if let ageRange = selectedAgeRange, ageRange != "Any", !ageMatchesRange(requestAge, selectedAgeRange!) {
                            return nil
                        }
                    }

                    // Handle location filtering by distance
                    if let requestLocation = request?.location {
                        let requestCoordinate = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
                        let distance = userLocation.distance(from: requestCoordinate) / 1609.34 // Convert meters to miles
                        if distance <= Double(preferredRadius) {
                            return request
                        }
                    }

                    return nil
                }

                print("Final requests count: \(connectionRequests.count)")
            }
        }
    }

    func ageMatchesRange(_ age: Int, _ range: String) -> Bool {
        switch range {
        case "18-25": return age >= 18 && age <= 25
        case "26-35": return age >= 26 && age <= 35
        case "36-50": return age >= 36 && age <= 50
        case "50+": return age >= 50
        default: return true
        }
    }
    
    
}

struct Invite: Codable {
    var email: String
    var message: String
}

struct ConnectionRequest: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var cuisine: String
    var event: String
    var age: Int
    var gender: String
    var blurb: String
    var date: String
    var location: GeoPoint
    var username: String
    var invitesSent: [Invite]

}

struct RequestCard: View {
    let request: ConnectionRequest
    let userLocation: CLLocation?
    @State private var showConnectView = false

    
    var distanceText: String {
        guard let userLocation = userLocation else { return "Distance unknown" }
        let requestCoordinate = CLLocation(latitude: request.location.latitude, longitude: request.location.longitude)
        let distance = userLocation.distance(from: requestCoordinate) / 1609.34 // Convert meters to miles
        return String(format: "%.1f miles away", distance)
    }
    
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color(hex: "#655745"))
                
                Text(request.username)
                    .font(.title)
                    .foregroundColor(Color(hex: "#655745"))
                
                HStack(spacing: 30) {
                    Text("Looking for: " + request.cuisine)
                        .font(.headline)
                        .foregroundColor(Color(hex: "#655745"))
                        .padding(.horizontal, 10)
                    
                }
                
                Text(request.blurb.isEmpty ? "\"Looking for company!\"" : "\"" + request.blurb + "\"")
                    .italic()
                    .font(.headline)
                    .foregroundColor(Color(hex: "#655745"))
                    .padding(5)
                
                Text(distanceText)  // Updated distance text
                    .font(.headline)
                    .foregroundColor(Color(hex: "#655745"))
                    
            }
            .frame(width: 280)
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color(UIColor.systemBrown).opacity(0.2)))
            
            Button(action: { showConnectView = true }) {
                Text("CONNECT")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#66574A"))
                    .foregroundColor(Color(hex: "#F6F3EC"))
                    .cornerRadius(30)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .sheet(isPresented: $showConnectView) {
                ConnectView(request: request)
            }
        }
    }
}


#Preview {
    MainTabView()
}
