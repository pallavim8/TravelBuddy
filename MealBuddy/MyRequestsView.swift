//
//  MyRequestsView.swift
//  MealBuddy
//
//  Created by Chinju on 2/22/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct MyRequestsView: View {
    @State private var userRequests: [ConnectionRequest] = []
    @State private var isLoading: Bool = true
    @State private var selectedInvite: Invite?
    @State private var showInviteDetails = false
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
                    Text("You have no requests yet!\n Make a new request to start matching with people in your area")
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
                                    onInviteTap: { invite in
                                        selectedInvite = invite
                                        handleMatchRequest(invite: invite, requestID: request.id)
                                    }
                                )
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .onAppear {
                fetchUserRequests()
            }
            .padding()
            .background(Color(hex: "#eee2d2"))
            .cornerRadius(20)
            .sheet(isPresented: $showInviteDetails) {
                if let invite = selectedInvite {
                    InviteDetailsView(invite: invite)
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
                }
            }
    }

    // Handle the matching logic when an invite is clicked
    func handleMatchRequest(invite: Invite, requestID: String?) {
        guard let requestID = requestID else {
            print("Request ID is missing")
            return
        }

        // Here we update the "matches" array of the request document in Firestore
        db.collection("requests").document(requestID).updateData([
            "matches": FieldValue.arrayUnion([invite.email]) // Add invite email to matches array
        ]) { error in
            if let error = error {
                print("Error updating matches: \(error.localizedDescription)")
            } else {
                print("Match successfully added.")
            }
        }
    }
}


struct RequestCardView: View {
    let request: ConnectionRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(request.meal)
                .font(.headline)
                .foregroundColor(Color(hex: "#66574A"))
            
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
                // Prevent connecting to the user's own request
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
    let onInviteTap: (Invite) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            if invites.isEmpty {
                Text("No invites yet.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(invites, id: \.email) { invite in
                    HStack {
                        // NavigationLink is now wrapped around the Invite
                        NavigationLink(destination: InviteDetailsView(invite: invite)) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Color(hex: "#685643"))
                            
                            Text("\(invite.email) - \(invite.message)")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#66574A"))
                        }
                        .padding()
                        
                        Spacer()

                        // Click to match (handle invite click here)
                        Button(action: {
                            onInviteTap(invite)
                        }) {
                            Text(">")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color(hex: "#685643"))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 5)
                    .padding(.trailing, 15)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.systemGray6)))
                }
            }
        }
        .padding(.top, 10)
    }
}



struct InviteDetailsView: View {
    let invite: Invite
    let db = Firestore.firestore()
    
    @State private var userDetails: UserDetails?
    @State private var isLoading = true // Loading state to handle async fetch
    
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
                Text("Match")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(hex: "#685643"))
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            Spacer()
        }
        .onAppear {
            fetchUserDetails(email: invite.email)
        }
        .padding()
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#EEE2D2"))

    }
    
    func fetchUserDetails(email: String) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                isLoading = false
            } else {
                if let document = snapshot?.documents.first {
                    do {
                        userDetails = try document.data(as: UserDetails.self)
                        isLoading = false // Stop loading once details are fetched
                    } catch {
                        print("Error decoding user details: \(error.localizedDescription)")
                        isLoading = false
                    }
                } else {
                    isLoading = false
                }
            }
        }
    }

    func handleMatchRequest() {
        // Handle matching logic for invite here
        print("Matched with \(invite.email)")
    }
}

struct UserDetails: Codable {
    var username: String
    var dietaryRestrictions: String
    var priceRange: String
    var email: String

    enum CodingKeys: String, CodingKey {
        case username
        case dietaryRestrictions = "dietary_restrictions"
        case priceRange = "price_range"
        case email
    }
}

// Preview
#Preview {
    MyRequestsView()
}
