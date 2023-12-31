//
//  OptionsView.swift
//  Bootstrap
//
//  Created by haxi0 on 31.12.2023.
//

import SwiftUI

struct OptionsView: View {
    @Binding var showOptions: Bool
    @Binding var openSSH: Bool
    
    var body: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .regular))
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Settings")
                        .bold()
                        .frame(maxWidth: 250, alignment: .leading)
                        .font(Font.system(size: 35))
                    
                    Button {
                        withAnimation {
                            showOptions.toggle()
                        }
                    } label: {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red   )
                    }
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack {
                            Text("Options")
                                .foregroundColor(Color(UIColor.label))
                                .bold()
                                .font(Font.system(size: 20))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                            
                            VStack {
                                Toggle(isOn: $openSSH, label: {
                                    Label(
                                        title: { Text("OpenSSH") },
                                        icon: { Image(systemName: "terminal") }
                                    )
                                })
                            }
                        }
                        .frame(width: 253)
                        .padding(20)
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(20)
                                .opacity(0.5)
                        }
                        
                        VStack {
                            HStack {
                                Text("AppEnabler")
                                    .foregroundColor(Color(UIColor.label))
                                    .bold()
                                    .font(Font.system(size: 20))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                                
                                Button {
                                    rebuildappsFr()
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            
                            Divider()
                            
                            VStack {
                                Text("ToDo")
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
                }
                .frame(maxHeight: 550)
            }
        }
    }
}
