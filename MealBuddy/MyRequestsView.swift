import SwiftUI
import Firebase
import FirebaseAuth

struct MyRequestsView: View {
    @State private var userRequests: [ConnectionRequest] = []
    @State private var isLoading: Bool = true
    @State private var selectedInvite: Invite?
    @State private var selectedRequest: ConnectionRequest?
    @State private var showInviteDetails = false
    @State private var matchedInvites: [String: Bool] = [:]
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                Text("My Requests")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#655745"))
                    .padding()

                if isLoading {
                    ProgressView("Loading your requests...")
                        .padding()
                } else if userRequests.isEmpty {
                    Text("You have no requests yet!\nMake a new request to start matching with people in your area")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#726e69"))
                        .padding()
                        .multilineTextAlignment(.center)
                } else {
                    ScrollView {
                        ForEach(userRequests) { request in
                            VStack(alignment: .leading, spacing: 15) {
                                RequestCardView(request: request)
                                
                                InvitesView(
                                    invites: request.invitesSent,
                                    requestID: request.id,
                                    matchedInvites: $matchedInvites
                                )
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .onAppear { fetchUserRequests() }
            .padding()
            .background(Color(hex: "#EEE2D2"))
            .cornerRadius(20)
            .sheet(isPresented: $showInviteDetails, onDismiss: {
                // Refresh matched invites after dismissing the InviteDetailsView
                checkForMatchedInvites()
            }) {
                if let invite = selectedInvite, let request = selectedRequest {
                    InviteDetailsView(invite: invite, reqid: request.id ?? "", matchedInvites: $matchedInvites)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#EEE2D2"))
        }
    }

    func fetchUserRequests() {
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("User email is not available.")
            return
        }
        db.collection("requests")
            .whereField("email", isEqualTo: userEmail)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    print("Error fetching requests: \(error.localizedDescription)")
                } else {
                    userRequests = snapshot?.documents.compactMap { document in
                        try? document.data(as: ConnectionRequest.self)
                    } ?? []
                    checkForMatchedInvites()
                }
            }
    }

    func checkForMatchedInvites() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        db.collection("matches")
            .whereField("user1Email", isEqualTo: userEmail)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching matches: \(error.localizedDescription)")
                } else {
                    var updatedMatchedInvites = [String: Bool]()
                    for document in snapshot?.documents ?? [] {
                        let matchData = document.data()
                        if let user2Email = matchData["user2Email"] as? String {
                            updatedMatchedInvites[user2Email] = true
                        }
                    }
                    matchedInvites = updatedMatchedInvites // Update the state
                }
            }
    }
}

struct RequestCardView: View {
    let request: ConnectionRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
//            Text(request.meal)
//                .font(.headline)
//                .foregroundColor(Color(hex: "#66574A"))
            
            Text("Date: \(request.date)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text("Cuisine: \(request.cuisine)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(request.blurb.isEmpty ? "\"Looking for company!\"" : "\"" + request.blurb + "\"")
                .italic()
                .font(.body)
                .foregroundColor(Color(hex: "#66574A"))

            Divider()

            HStack {
                Text("Username: \(request.username)")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#655745"))

                Spacer()
                if Auth.auth().currentUser?.email != request.email {
                    Button(action: { /* Handle connect action */ }) {
                        Text("Connect")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(hex: "#8B7355"))
                            .cornerRadius(12)
                    }
                } else {
                    Text("Your Request")
                        .italic()
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white).shadow(radius: 5))
    }
}

struct InvitesView: View {
    let invites: [Invite]
    let requestID: String?
    @Binding var matchedInvites: [String: Bool]

    var body: some View {
        VStack(alignment: .leading) {
            if invites.isEmpty {
                Text("No invites yet.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(invites, id: \.email) { invite in
                    HStack {
                        if let requestID = requestID {
                            NavigationLink(destination: InviteDetailsView(invite: invite, reqid: requestID, matchedInvites: $matchedInvites)) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Color(hex: "#685643"))
                                
                                Text("\(invite.email) - \(invite.message)")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#66574A"))
                                    .padding(.vertical, 5)
                                Spacer()
                                Text(">")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .cornerRadius(10)
                            }
                            .background(matchedInvites[invite.email] == true ? Color.gray : Color.white)
                            .padding()
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 5)
                    .padding(.trailing, 15)
                    .background(RoundedRectangle(cornerRadius: 10).fill(matchedInvites[invite.email] == true ? Color.gray : Color.white))
                }
            }
        }
        .padding(.top, 10)
    }
}

struct InviteDetailsView: View {
    let invite: Invite
    let reqid: String
    @Binding var matchedInvites: [String: Bool]
    let db = Firestore.firestore()
    
    @State private var userDetails: UserDetails?
    @State private var isLoading = true
    @State private var matchStatus: MatchStatus = .notMatched
    
    enum MatchStatus {
        case notMatched
        case matchedWithSomeoneElse
        case matchedWithInvitee
    }
    
    var body: some View {
        VStack {
            Text("Invite Details")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            if isLoading {
                ProgressView("Loading user details...")
                    .padding()
            } else {
                Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(Color(hex: "#655745"))
                                            .padding(.bottom, 10)
                if let userDetails = userDetails {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Invited by: \(invite.email)")
                            .font(.headline)

                        Text("Message: \(invite.message)")
                            .font(.subheadline)

                        // Showing the user's details
                        Text("Username: \(userDetails.username)")
                            .font(.subheadline)

                        Text("Dietary Restrictions: \(userDetails.dietaryRestrictions)")
                            .font(.subheadline)

                        Text("Preferred Price Range: \(userDetails.priceRange)")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color(UIColor.systemGray6)))
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white).shadow(radius: 5))
                    .padding(.horizontal)
                } else {
                    Text("No details available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: {
                handleMatchRequest()
            }) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(buttonColor)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            Spacer()
        }
        .onAppear {
            fetchUserDetails(email: invite.email)
            checkMatchStatus()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#EEE3D2"))
    }

    func fetchUserDetails(email: String) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, _ in
            userDetails = snapshot?.documents.compactMap { try? $0.data(as: UserDetails.self) }.first
            isLoading = false
        }
    }

    func checkMatchStatus() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        
        // Check if the user is matched with the invitee
        db.collection("matches")
            .whereField("requestID", isEqualTo: reqid)
            .whereField("user1Email", isEqualTo: currentUserEmail)
            .whereField("user2Email", isEqualTo: invite.email)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking for existing match: \(error.localizedDescription)")
                } else if let snapshot = snapshot, !snapshot.isEmpty {
                    // User is matched with the invitee
                    matchStatus = .matchedWithInvitee
                } else {
                    // Check if the user is matched with someone else
                    db.collection("matches")
                        .whereField("requestID", isEqualTo: reqid)
                        .whereField("user1Email", isEqualTo: currentUserEmail)
                        .getDocuments { snapshot, _ in
                            if let snapshot = snapshot, !snapshot.isEmpty {
                                matchStatus = .matchedWithSomeoneElse
                            } else {
                                matchStatus = .notMatched
                            }
                        }
                }
            }
    }

    func handleMatchRequest() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }

        switch matchStatus {
        case .notMatched:
            // Create a new match with the invitee
            let matchData: [String: Any] = [
                "user1Email": currentUserEmail,
                "user2Email": invite.email,
                "requestID": reqid,
                "messages": []
            ]
            
            db.collection("matches").addDocument(data: matchData) { error in
                if let error = error {
                    print("Error creating match: \(error.localizedDescription)")
                } else {
                    print("Successfully created match with \(invite.email)")
                    matchStatus = .matchedWithInvitee
                }
            }

        case .matchedWithSomeoneElse:
            // Inform the user that they're already matched with someone else
            print("You are already matched with someone else on this request.")

        case .matchedWithInvitee:
            // Unmatch the user
            db.collection("matches")
                .whereField("requestID", isEqualTo: reqid)
                .whereField("user1Email", isEqualTo: currentUserEmail)
                .whereField("user2Email", isEqualTo: invite.email)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error checking for match to unmatch: \(error.localizedDescription)")
                    } else {
                        // Match found, delete it
                        snapshot?.documents.first?.reference.delete() { error in
                            if let error = error {
                                print("Error deleting match: \(error.localizedDescription)")
                            } else {
                                print("Successfully unmatched with \(invite.email)")
                                matchStatus = .notMatched
                            }
                        }
                    }
                }
        }
    }

    var buttonText: String {
        switch matchStatus {
        case .notMatched:
            return "Match"
        case .matchedWithSomeoneElse:
            return "You are already matched"
        case .matchedWithInvitee:
            return "Unmatch"
        }
    }

    var buttonColor: Color {
        switch matchStatus {
        case .notMatched:
            return Color(hex: "#685643")
        case .matchedWithSomeoneElse:
            return Color.gray
        case .matchedWithInvitee:
            return Color(hex: "#bfbdbc")
        }
    }
}



struct UserDetails: Codable {
    var username: String
    var dietaryRestrictions: String
    var priceRange: String
    var email: String
}

// Preview
#Preview {
    MyRequestsView()
}
