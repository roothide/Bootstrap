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
                .onTapGesture {
                   showCredits = false
                }
            
            VStack {
                VStack {
                    Text("Credits")
                        .bold()
                        .frame(maxWidth: 250, alignment: .center )
                        .font(Font.system(size: 35))
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
                    .background {
                        Color(UIColor.systemBackground)
                            .cornerRadius(20)
                            .opacity(0.5)
                    }
                }
                .frame(maxHeight: 550)
            }
            .zIndex(2)
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
