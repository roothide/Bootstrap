//
//  CreditsView.swift
//  Bootstrap
//
//  Created by haxi0 on 31.12.2023.
//

import SwiftUI

struct CreditsView: View {
    @Binding var showCredits: Bool
    
    let credits: [String: String] = CREDITS as! Dictionary
    
    var body: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .regular))
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Credits")
                        .bold()
                        .frame(maxWidth: 250, alignment: .leading)
                        .font(Font.system(size: 35))
                    Button {
                        Haptic.shared.play(.light)
                        withAnimation(niceAnimation) {
                            showCredits = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .foregroundColor(.primary)
                            .frame(width: 25, height: 25)
                            .padding(6)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(.infinity)
                }
                
                ScrollView {
                    VStack {
                        
                        VStack {
                            ForEach(credits.sorted(by: { $0.key < $1.key }), id: \.key) { (name, link) in
                                creditStack(name: name, link: link)
                            }
                        }
                    }
                    .frame(width: 253)
                    .padding(20)
                }
                .background {
                    Color(UIColor.systemBackground)
                        .cornerRadius(20)
                        .opacity(0.5)
                }
                .frame(maxHeight: 550)
            }
            .scaleEffect(showCredits ? 1 : 0.9)
        }
    }
    
    private func creditStack(name: String, link: String) -> some View {
        HStack {
            Text(name)
                .bold()
            Spacer()
            Button {
                if let url = URL(string: link) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Image(systemName: "link")
            }
        }
        .padding(5)
    }
}
