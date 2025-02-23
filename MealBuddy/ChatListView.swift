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
                        .foregroundColor(.gray)
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
                                    Text(match.user2Email)
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
                    }
                }
            }
            .onAppear { fetchMatches() }
            .padding()
            .background(Color(hex: "#EEE2D2"))
        }
    }
    
    func fetchMatches() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        db.collection("matches")
            .whereField("user1Email", isEqualTo: userEmail)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    print("Error fetching matches: \(error.localizedDescription)")
                } else {
                    matches = snapshot?.documents.compactMap { document in
                        try? document.data(as: Match.self)
                    } ?? []
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
}

struct Message: Codable {
    var sender: String
    var text: String
    var timestamp: Timestamp
}


#Preview {

    ChatListView()

}
