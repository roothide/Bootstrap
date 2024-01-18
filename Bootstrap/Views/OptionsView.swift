//
//  OptionsView.swift
//  Bootstrap
//
//  Created by haxi0 on 31.12.2023.
//

import SwiftUI

class toggleState: ObservableObject {
    @Published var state:Bool
    init(state: Bool) {
        self.state = state
    }
}

struct OptionsView: View {
    @Binding var showOptions: Bool
    @Binding var tweakEnable: Bool
    @StateObject var opensshStatus = toggleState(state: updateOpensshStatus(false))
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            ZStack {
                if showOptions {
                    VisualEffectView(effect: UIBlurEffect(style: .regular))
                        .ignoresSafeArea()
                        .onTapGesture {
                            showOptions = false
                        }
                        .zIndex(2)
            
                    VStack {
                        VStack {
                            Text("Settings")
                                .bold()
                                .frame(maxWidth: 250, alignment: .center)
                                .font(Font.system(size: 35))
                        }

                        VStack {
                            VStack {  
                                Toggle(isOn: $tweakEnable, label: {
                                    Label(
                                        title: { Text("Tweak Enable") },
                                        icon: { Image(systemName: "wrench.and.screwdriver") }
                                    )
                                }).padding(5)
                                .onChange(of: tweakEnable) { newValue in
                                    tweaEnableAction(newValue)
                                }
                            
                                Toggle(isOn: Binding(get: {opensshStatus.state}, set: {
                                    opensshStatus.state = opensshAction($0)
                                }), label: {
                                    Label(
                                        title: { Text("OpenSSH") },
                                        icon: { Image(systemName: "terminal") }
                                    )
                                })
                                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("opensshStatusNotification"))) { obj in
                                    DispatchQueue.global(qos: .utility).async {
                                        let newStatus = (obj.object as! NSNumber).boolValue
                                        opensshStatus.state = newStatus
                                    }
                                }
                                .padding(5)
                            

                                Divider().padding(10)
                            
                                VStack(alignment: .leading, spacing: 12, content: { 
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        rebuildappsAction()
                                    } label: {
                                        Label(
                                            title: { Text("Rebuild Apps").foregroundColor(colorScheme == .dark ? .white : .black) },
                                            icon: { Image(systemName: "arrow.clockwise") }
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .foregroundColor(!isSystemBootstrapped() ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                    }
                                    .frame(width: 250)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(.gray, lineWidth: 1)
                                            .opacity(0.3)
                                    )
                                    .disabled(!isSystemBootstrapped())
                                
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        rebuildIconCacheAction()
                                    } label: {
                                        Label(
                                            title: { Text("Rebuild Icon Cache").foregroundColor(colorScheme == .dark ? .white : .black) },
                                            icon: { Image(systemName: "arrow.clockwise") }
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .foregroundColor(!isSystemBootstrapped() ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                    }
                                    .frame(width: 250)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(.gray, lineWidth: 1)
                                            .opacity(0.3)
                                    )
                                    .disabled(!isSystemBootstrapped())
                                
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        reinstallPackageManager()
                                    } label: {
                                        Label(
                                            title: { Text("Reinstall Sileo").foregroundColor(colorScheme == .dark ? .white : .black) },
                                            icon: { Image(systemName: "shippingbox") }
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .foregroundColor(!isSystemBootstrapped() ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                    }
                                    .frame(width: 250)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(.gray, lineWidth: 1)
                                            .opacity(0.3)
                                    )
                                    .disabled(!isSystemBootstrapped())
                                
                                    if isBootstrapInstalled() {
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            unbootstrapAction()
                                        } label: {
                                            Label(
                                                title: { Text("Uninstall").foregroundColor(colorScheme == .dark ? .white : .black)},
                                                icon: { Image(systemName: "trash") }
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .foregroundColor(isSystemBootstrapped() ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                        }
                                        .frame(width: 250)
                                        .background(Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.gray, lineWidth: 1)
                                                .opacity(0.3)
                                        )
                                        .disabled(isSystemBootstrapped())
                                    }
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
                    }
                    .zIndex(3)
                }
            }
            .frame(maxHeight: 550)
        }
    }
}
