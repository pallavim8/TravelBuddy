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

            Text("Chat View")
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

struct HomeView: View {
    @State private var userEmail: String = ""
    @State private var userName: String = ""
    @State private var isLoggedOut = false
    @State private var connectionRequests: [ConnectionRequest] = []
    @State private var isLoading: Bool = true
    @State private var selectedDate = Date()
    @State private var selectedMeal = "Lunch"
    @State private var currentIndex = 0
    @State private var userLocation: CLLocation?

    
    let meals = ["Breakfast", "Lunch", "Dinner"]
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
                        
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .padding(5)
                            .colorScheme(.dark)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#655745")))
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .tint(Color(hex: "#8B7355"))
                            .accentColor(Color(hex: "#8B7355"))
                        
                        Menu {
                                                ForEach(meals, id: \.self) { meal in
                                                    Button(meal) {
                                                        selectedMeal = meal
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    Text(selectedMeal)
                                                        .lineLimit(1)
                                                        .frame(minWidth: 80)
                                                    Image(systemName: "chevron.down")
                                                }
                                                .frame(maxWidth: 120)
                                                .padding(12)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#655745")))
                                                .foregroundColor(Color(hex: "#F6F3EC"))
                                            }
                                            .padding(.horizontal, 5)

                        
                        Button(action: fetchConnectionRequests) {
                            Image(systemName: "magnifyingglass")
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
                                    .foregroundColor(.brown).offset(y: -45)
                            }
                            Spacer()
                            RequestCard(request: connectionRequests[currentIndex], userLocation: userLocation)
                            
//                            Spacer()
                            Button(action: {
                                if currentIndex < connectionRequests.count - 1 { currentIndex += 1 }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.largeTitle)
                                    .foregroundColor(.brown).offset(y:-45)
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
        
        let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let formattedDate = dateFormatter.string(from: selectedDate)
        
        guard let userLocation = userLocation else {
            print("User location not available")
            return
        }
        
        let userRef = db.collection("users").document(Auth.auth().currentUser?.uid ?? "unknown")
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let preferredRadius = document.data()?["preferred_radius"] as? Int ?? 10
                
                db.collection("requests")
                    .whereField("meal", isEqualTo: selectedMeal)
                    .whereField("date", isEqualTo: formattedDate)
                    .getDocuments { snapshot, error in
                        isLoading = false
                        if let error = error {
                            print("Error fetching requests: \(error.localizedDescription)")
                        } else {
                            connectionRequests = snapshot?.documents.compactMap { document in
                                let request = try? document.data(as: ConnectionRequest.self)
                                if let requestLocation = request?.location {
                                    let requestCoordinate = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
                                    let distance = userLocation.distance(from: requestCoordinate) / 1609.34 // Convert meters to miles
                                    
                                    return distance <= Double(preferredRadius) ? request : nil
                                }
                                return nil
                            } ?? []
                        }
                    }
            } else {
                print("User preferences not found")
            }
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
    var diningOption: String
    var meal: String
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
                    
                    if request.diningOption == "Fast Food" {
                        ZStack {
                            Image(systemName: "wind")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .offset(x: 30)
                                .foregroundColor(Color(hex: "#655745"))
                                .scaleEffect(x: -1, y: 1)
                            
                            Image(systemName: "figure.run")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(Color(hex: "#655745"))
                        }
                    } else {
                        Image(systemName: "chair")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color(hex: "#655745"))
                    }
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
