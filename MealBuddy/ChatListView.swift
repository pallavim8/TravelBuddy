//
//  ChatListView.swift
//  MealBuddy
//
//  Created by Chinju on 2/22/25.
//


import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore


struct ChatListView: View {
    @State private var matches: [Match] = []
    @State private var isLoading = true
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Chats")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#655745"))
                    .padding()

                if isLoading {
                    ProgressView("Loading chats...")
                        .padding()
                } else if matches.isEmpty {
                    Text("No chats available. Start matching to chat!")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    List(matches) { match in
                        NavigationLink(destination: ChatView(match: match)) {
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                                VStack(alignment: .leading) {
                                    Text(match.mealDetails ?? "Fetching details...")
                                        .font(.headline)
                                        .foregroundColor(Color(hex: "#66574A"))
                                    Text("Tap to chat")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                        .listRowBackground(Color(hex: "#dbc9b1"))
                        .cornerRadius(30)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
            }
            .onAppear { fetchMatches() }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#EEE3D2"))
        }
    }
    
    func fetchMatches() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }

        db.collection("matches")
            .whereFilter(Filter.orFilter([
                Filter.whereField("user1Email", isEqualTo: userEmail),
                Filter.whereField("user2Email", isEqualTo: userEmail)
            ]))
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    print("Error fetching matches: \(error.localizedDescription)")
                } else {
                    var fetchedMatches: [Match] = []
                    let group = DispatchGroup()

                    for document in snapshot?.documents ?? [] {
                        if var match = try? document.data(as: Match.self) {
                            print("Fetched match with requestID: \(match.requestID)")
                            group.enter()

                            db.collection("requests").document(match.requestID).getDocument { requestSnapshot, requestError in
                                if let requestError = requestError {
                                    print("Error fetching request details: \(requestError.localizedDescription)")
                                }

                                if let requestData = requestSnapshot?.data() {
                                    let meal = requestData["meal"] as? String ?? "Unknown"
                                    let mealDate = requestData["date"] as? String ?? "Unknown Date"
                                    match.mealDetails = "\(meal) - \(mealDate)"
                                    print("Updated match with meal details: \(match.mealDetails ?? "N/A")")
                                } else {
                                    print("No request data found for requestID: \(match.requestID)")
                                }

                                DispatchQueue.main.async {
                                    fetchedMatches.append(match)
                                }
                                group.leave()
                            }
                        }
                    }

                    group.notify(queue: .main) {
                        DispatchQueue.main.async {
                            self.matches = fetchedMatches
                            print("Final matches updated: \(self.matches)")
                        }
                    }
                }
            }
    }
}

struct Match: Identifiable, Codable {
    @DocumentID var id: String?
    var user1Email: String
    var user2Email: String
    var requestID: String
    var messages: [Message]
    var mealDetails: String?  // Add this to store meal type + date
}

struct Message: Codable {
    var sender: String
    var text: String
    var timestamp: Timestamp
}


#Preview {

    ChatListView()

}
