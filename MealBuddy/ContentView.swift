import SwiftUI



extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        if hex.count == 6 {
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        } else {
            r = 1.0
            g = 1.0
            b = 1.0
        }
        self.init(red: r, green: g, blue: b)
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                Image("mealbuddy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                
                Text("MEALBUDDY")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.black)
                    .tracking(1)
                
                
                
                Text("Connect with foodies nearby\nfor culinary adventures")
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(hex: "#554F48"))
                
                
                
                //            Button(action: {
                //                print("Join Now tapped")
                //            }) {
                //
                //                Text("JOIN NOW")
                //                    .font(.system(size: 15, weight: .medium))
                //                    .frame(maxWidth: .infinity)
                //                    .padding()
                //                    .background(Color(hex: "#66574A"))
                //                    .foregroundColor(Color(hex: "#F6F3EC"))
                //                    .cornerRadius(30)
                //            }
                
                
                NavigationLink(destination: AuthView()) {
                    Text("JOIN NOW")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#66574A"))
                        .foregroundColor(Color(hex: "#F6F3EC"))
                        .cornerRadius(30)
                }
                
                .padding(.horizontal, 40)
                .padding(.vertical, 30)
            }
            
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#EEE2D2"))
        .navigationBarBackButtonHidden(true)
        }
            

    }

}



#Preview {
    ContentView()
}
