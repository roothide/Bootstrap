//
//  OptionsView.swift
//  Bootstrap
//
//  Created by haxi0 on 31.12.2023.
//

import SwiftUI

struct OptionsView: View {
    @Binding var showOptions: Bool
    @State var tweakEnable: Bool = !isSystemBootstrapped() || FileManager.default.fileExists(atPath: jbroot("/var/mobile/.tweakenabled"))
    @State var opensshStatus: Bool = updateOpensshStatus(false)
    
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
                            .resizable()
                            .foregroundColor(.red)
                            .frame(width: 30, height: 30)
                    }
                }
                
                //ScrollView {
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
                            
                            Toggle(isOn: $opensshStatus, label: {
                                Label(
                                    title: { Text("OpenSSH") },
                                    icon: { Image(systemName: "terminal") }
                                )
                            }).padding(5)
                            .onChange(of: opensshStatus) { newValue in
                                opensshStatus = opensshAction(newValue)
                            }
                            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("opensshStatusNotification"))) { obj in
                                DispatchQueue.global(qos: .utility).async {
                                    let newStatus = (obj.object as! NSNumber).boolValue
                                    if newStatus != opensshStatus {
                                        opensshStatus = newStatus
                                    }
                                }
                            }
                            

                            Divider().padding(10)
                            
                            VStack(alignment: .leading, spacing: 12, content: {
                                
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    respringAction()
                                } label: {
                                    Label(
                                        title: { Text("Respring") },
                                        icon: { Image(systemName: "arrow.clockwise") }
                                    )
                                }
                                .buttonStyle(DopamineButtonStyle())
                                .disabled(!isSystemBootstrapped())
                                
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    rebuildappsAction()
                                } label: {
                                    Label(
                                        title: { Text("Rebuild Apps") },
                                        icon: { Image(systemName: "arrow.clockwise") }
                                    )
                                }
                                .buttonStyle(DopamineButtonStyle())
                                .disabled(!isSystemBootstrapped())
                                
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    rebuildIconCacheAction()
                                } label: {
                                    Label(
                                        title: { Text("Rebuild Icon Cache") },
                                        icon: { Image(systemName: "arrow.clockwise") }
                                    )
                                }
                                .buttonStyle(DopamineButtonStyle())
                                .disabled(!isSystemBootstrapped())
                                
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    reinstallPackageManager()
                                } label: {
                                    Label(
                                        title: { Text("Reinstall Sileo & Zebra") },
                                        icon: { Image(systemName: "shippingbox") }
                                    )
                                }
                                .buttonStyle(DopamineButtonStyle())
                                .disabled(!isSystemBootstrapped())
                                
                                if isBootstrapInstalled() {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        unbootstrapAction()
                                    } label: {
                                        Label(
                                            title: { Text("Uninstall") },
                                            icon: { Image(systemName: "trash") }
                                        )
                                    }
                                    .buttonStyle(DopamineButtonStyle())
                                    .disabled(isSystemBootstrapped())
                                }
                            })
                        }
                        .frame(width: 253)
                        .padding(20)
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(20)
                                .opacity(0.5)
                        }
                    }
                //}
            }
            .frame(maxHeight: 550)
        }
    }
}


