//
//  ChatView.swift
//  MealBuddy
//
//  Created by Chinju on 2/22/25.
//


import SwiftUI
import Firebase
import FirebaseAuth

struct ChatView: View {
    let match: Match
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    let db = Firestore.firestore()
    
    var body: some View {
        VStack {
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
        .navigationTitle("Chat with \(match.user2Email)")
        .onAppear { fetchMessages() }
    }

    func fetchMessages() {
        db.collection("matches").document(match.id ?? "")
            .addSnapshotListener { document, error in
                if let document = document, document.exists {
                    if let matchData = try? document.data(as: Match.self) {
                        self.messages = matchData.messages.sorted { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
                    }
                }
            }
    }

    func sendMessage() {
        guard !newMessage.isEmpty, let userEmail = Auth.auth().currentUser?.email else { return }

        let message = Message(sender: userEmail, text: newMessage, timestamp: Timestamp(date: Date()))
        
        var updatedMessages = messages
        updatedMessages.append(message)
        
        db.collection("matches").document(match.id ?? "").updateData([
            "messages": updatedMessages.map { try! Firestore.Encoder().encode($0) }
        ]) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
            } else {
                newMessage = ""
            }
        }
    }
}
