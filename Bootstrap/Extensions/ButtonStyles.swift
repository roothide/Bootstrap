//
//  ButtonStyles.swift
//  Bootstrap
//
//  Created by haxi0 on 02.01.2024.
//

import SwiftUI

struct DopamineButtonStyle: ButtonStyle { // ty to dopamine for button style inspiration :troll:
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .frame(width: 250)
            .background(Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white, lineWidth: 1)
                    .opacity(0.2)
            )
    }
}
