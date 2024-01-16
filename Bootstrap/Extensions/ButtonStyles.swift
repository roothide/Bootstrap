//
//  ButtonStyles.swift
//  Bootstrap
//
//  Created by haxi0 on 02.01.2024.
//

import SwiftUI


struct DopamineButtonStyle: ButtonStyle { // ty to dopamine for button style inspiration :troll:
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .frame(width: 250)
            .background(Color.clear)
            .cornerRadius(10)
            // change the text color based on if it's disabled
            .foregroundColor(isEnabled ? .black : .gray)
            // make the button a bit more translucent when pressed
            .opacity(configuration.isPressed ? 0.3 : 1.0)
            // make the button a bit smaller when pressed
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.gray, lineWidth: 1)
                    .opacity(isEnabled ? 0.3 : 0.1)
            )
    }
}
