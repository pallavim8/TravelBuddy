import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ConnectView: View {
    let request: ConnectionRequest
    @State private var inviteMessage: String = "Looking forward to meeting you :)"
    @State private var hasSentInvite = false
    @Environment(\.presentationMode) var presentationMode
    
    // Move db initialization to a computed property
    private var db: Firestore {
        Firestore.firestore()
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Send an invite to \(request.username)?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)

            Text("Add a short message to personalize your invite:")
                .font(.body)
                .foregroundColor(.gray)

            TextEditor(text: $inviteMessage)
                .frame(height: 100)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                .cornerRadius(12)

            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)))
                        .foregroundColor(.black)
                }

                Button(action: sendInvite) {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#66574A")))
                        .foregroundColor(Color(hex: "#F6F3EC"))
                }
                .disabled(hasSentInvite)
            }
            .padding(.top)

            Spacer()
        }
        .padding()
        .frame(width: 350, height: 300)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 10))
    }

    func sendInvite() {
        print("sending invite")
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            print("User email is nil")
            return
        }
        
        if request.invitesSent.contains(where: { $0.email == currentUserEmail }) {
            print("Invite already sent!")
            return
        }

        let invite = Invite(email: currentUserEmail, message: inviteMessage)
        let updatedInvitesSent = request.invitesSent + [invite]
        
        guard let requestId = request.id else {
            print("Request ID is nil")
            return
        }

        // Convert invites to array of dictionaries for Firestore
        let invitesData = updatedInvitesSent.map { invite -> [String: Any] in
            return [
                "email": invite.email,
                "message": invite.message
            ]
        }

        db.collection("requests").document(requestId).updateData([
            "invitesSent": invitesData
        ]) { error in
            if let error = error {
                print("Error sending invite: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    hasSentInvite = true
                    presentationMode.wrappedValue.dismiss()
                }
                print("Invite sent successfully!")
            }
        }
    }
}

// Preview helper
struct MockConnectionRequest {
    static let sample = ConnectionRequest(
        id: "sample-id",
        email: "test@example.com",
        cuisine: "Italian",
        diningOption: "Dine-in",
        meal: "Lunch",
        blurb: "Looking for lunch buddies!",
        date: "2025-02-22",
        location: GeoPoint(latitude: 0, longitude: 0),
        username: "Test User",
        invitesSent: []
    )
}

#Preview {
    ConnectView(request: MockConnectionRequest.sample)
}
