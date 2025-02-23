//
//  SplashScreen.swift
//  MealBuddy
//
//  Created by Chinju on 2/22/25.
//


import SwiftUI


struct SplashScreen: View {
    @State private var scale = 0.7
    @State private var offsetY: CGFloat = 0 // Start at the center
    @Binding var isActive: Bool

    

    var body: some View {
        VStack {
            VStack {
                Image("travelbuddy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)


                Text("TRAVELBUDDY")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.black)
                    .tracking(1)

            }

            .scaleEffect(scale)
            .offset(y: offsetY) // Apply the offset
            .onAppear {

                withAnimation(.easeIn(duration: 0.7)) {
                    self.scale = 1
                    self.offsetY = -95 // Move the content up by 50 points during the animation

                }

            }

        }

        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    self.isActive = true
                }
            }

        }

        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#EEE2D2"))

    }

}
