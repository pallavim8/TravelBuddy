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

    @State private var scale = 0.0

    @State private var opacityText = 0.0

    @State private var opacityButton = 0.0

    @State private var offsetText = 20.0

    @State private var offsetButton = 20.0



    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                Image("travelbuddy")

                    .resizable()

                    .scaledToFit()

                    .frame(width: 300, height: 300)

                

                Text("TRAVELBUDDY")

                    .font(.system(size: 40, weight: .heavy))

                    .foregroundColor(.black)

                    .tracking(1)

                    .offset(y: -5)

                

                VStack {

                    Text("Moving to a new city is hard. Making new friends shouldn’t be.")

                        .font(.system(size: 18, weight: .medium))

                        .multilineTextAlignment(.center)

                        .foregroundColor(Color(hex: "#554F48"))

                        .opacity(opacityText)

                        .offset(y: offsetText)
                    
                        .padding(.horizontal, 15)

                    

                    NavigationLink(destination: AuthView()) {

                        Text("JOIN NOW")

                            .font(.system(size: 15, weight: .medium))

                            .frame(maxWidth: .infinity)

                            .padding()

                            .background(Color(hex: "#66574A"))

                            .foregroundColor(Color(hex: "#F6F3EC"))

                            .cornerRadius(30)

                            .opacity(opacityButton)

                            .offset(y: offsetButton)

                    }

                    .padding(.horizontal, 40)

                    .padding(.vertical, 30)

                }

                .scaleEffect(scale)

                .onAppear {

                    withAnimation(.easeIn(duration: 0.7)) {

                        self.scale = 1

                    }

                    withAnimation(.easeIn(duration: 0.7).delay(0.3)) {

                        self.opacityText = 1

                        self.offsetText = 0

                    }

                    withAnimation(.easeIn(duration: 0.7).delay(0.6)) {

                        self.opacityButton = 1

                        self.offsetButton = 0

                    }

                }

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
