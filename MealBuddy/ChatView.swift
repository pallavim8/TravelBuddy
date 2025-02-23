import SwiftUI
import Firebase
import FirebaseAuth
import Foundation

struct YelpResponse: Codable {
    let businesses: [YelpBusiness]
}

struct YelpBusiness: Codable, Identifiable {
    let id: String
    let name: String
    let location: YelpLocation
    let rating: Double?

    struct YelpLocation: Codable {
        let address1: String?
        let city: String?
        let state: String?
        let zip_code: String?
        
        var fullAddress: String {
            [address1, city, state, zip_code].compactMap { $0 }.joined(separator: ", ")
        }
    }
}

func fetchYelpPlaces(latitude: Double, longitude: Double, cuisine: String, maxDistance: Double, completion: @escaping ([YelpBusiness]) -> Void) {
    let apiKey = "d1nLq_zTl0OHO8T5bmU1I3yLeNNaZoKEzWezPhMQPcgdYlxnrhZhP7fHijkmExpXYULg5f1rkUtK2Ha9Ugkp_nAI4XyQXkghKEFzl8pdpfnuEM5q1TYv1j2pHxsZZHYx" // Replace with your actual Yelp API key
    let urlString = "https://api.yelp.com/v3/businesses/search?term=\(cuisine)&latitude=\(latitude)&longitude=\(longitude)&radius=\(Int(maxDistance * 1609.34))&sort_by=rating&limit=5"
    
    guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
        print("Invalid Yelp URL")
        completion([])
        return
    }

    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.httpMethod = "GET"

    print("Fetching Yelp places with URL: \(urlString)") // Print the URL being requested

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Yelp API Error: \(error?.localizedDescription ?? "Unknown error")")
            completion([])
            return
        }

        do {
            let decodedResponse = try JSONDecoder().decode(YelpResponse.self, from: data)
            print("Yelp Response: \(decodedResponse.businesses.count) places found")
            DispatchQueue.main.async {
                completion(decodedResponse.businesses)
            }
        } catch {
            print("Failed to decode Yelp response: \(error.localizedDescription)")
            completion([])
        }
    }.resume()
}

struct ChatView: View {
    let match: Match
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var otherUserName: String? = nil
    @State private var recommendedPlaces: [YelpBusiness] = [] // Stores restaurant recommendations
    let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            if messages.isEmpty && !recommendedPlaces.isEmpty {
                VStack {
                    Text("No messages yet! Here are some places you might like:")
                        .font(.headline)
                        .padding()
                    
                    List(recommendedPlaces) { place in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(place.name)
                                    .font(.headline)
                                Text("\(place.location.fullAddress) - \(place.rating ?? 0, specifier: "%.1f") ⭐")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages, id: \.timestamp) { message in
                            HStack {
                                if message.sender == Auth.auth().currentUser?.email {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
            }

            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .padding()
            }
        }
        .navigationTitle("Chat with \(otherUserName ?? "Loading...")")
        .onAppear {
            fetchMessages()
            fetchOtherUserName()
        }
    }

    func fetchMessages() {
        print("Fetching messages for match ID: \(match.id ?? "Unknown ID")") // Debug message
        db.collection("matches").document(match.id ?? "")
            .addSnapshotListener { document, error in
                if let document = document, document.exists {
                    if let matchData = try? document.data(as: Match.self) {
                        self.messages = matchData.messages.sorted { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
                        
                        print("Messages fetched: \(self.messages.count) messages") // Debug message
                        
                        if messages.isEmpty {
                            print("No messages found. Fetching recommendations...") // Debug message
                            fetchRecommendations() // Only fetch places if no messages exist
                        }
                    }
                } else {
                    print("Error fetching match data: \(error?.localizedDescription ?? "Unknown error")") // Debug message
                }
            }
    }

    func sendMessage() {
        guard !newMessage.isEmpty, let userEmail = Auth.auth().currentUser?.email else { return }

        let message = Message(sender: userEmail, text: newMessage, timestamp: Timestamp(date: Date()))
        
        var updatedMessages = messages
        updatedMessages.append(message)
        
        print("Sending message: \(newMessage)") // Debug message

        db.collection("matches").document(match.id ?? "").updateData([
            "messages": updatedMessages.map { try! Firestore.Encoder().encode($0) }
        ]) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)") // Debug message
            } else {
                print("Message sent successfully!") // Debug message
                newMessage = ""
            }
        }
    }

    func fetchOtherUserName() {
        let currentUserEmail = Auth.auth().currentUser?.email ?? ""
        let otherUserEmail = match.user1Email == currentUserEmail ? match.user2Email : match.user1Email
        
        print("Fetching username for user: \(otherUserEmail)") // Debug message
        
        db.collection("users").whereField("email", isEqualTo: otherUserEmail)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching username: \(error.localizedDescription)") // Debug message
                } else if let document = snapshot?.documents.first {
                    self.otherUserName = document.data()["username"] as? String ?? "Unknown"
                    print("Fetched username: \(self.otherUserName ?? "Unknown")") // Debug message
                }
            }
    }

    func fetchRecommendations() {
        print("Fetching recommendations for match ID: \(match.requestID)") // Debug message
        db.collection("requests").document(match.requestID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let preferredCuisine = data?["cuisine"] as? String ?? "Any"
                let preferredDistance = data?["maxDistance"] as? Double ?? 10.0
                let userLocation = data?["location"] as? [String: Double]  // Location should be a dictionary

                print("Request data: Cuisine = \(preferredCuisine), Max Distance = \(preferredDistance), Location = \(userLocation ?? [:])") // Debug message
                
                // Check if location is valid
                if let location = userLocation, let latitude = location["latitude"], let longitude = location["longitude"], latitude != 0.0, longitude != 0.0 {
                    fetchYelpPlaces(latitude: latitude, longitude: longitude, cuisine: preferredCuisine, maxDistance: preferredDistance) { places in
                        print("Yelp recommendations fetched: \(places.count) places found") // Debug message
                        self.recommendedPlaces = places
                    }
                } else {
                    print("Invalid location data. Cannot fetch recommendations.") // Debug message
                    // Handle invalid location case (e.g., use a default location)
                }
            } else {
                print("Error fetching request data: \(error?.localizedDescription ?? "Unknown error")") // Debug message
            }
        }
    }
}

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let rating: Double
}
