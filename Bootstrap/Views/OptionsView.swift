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
    @StateObject var allowURLSchemes = toggleState(state: isBootstrapInstalled() && FileManager.default.fileExists(atPath: jbroot("/var/mobile/.allow_url_schemes")))
    @StateObject var opensshStatus = toggleState(state: updateOpensshStatus(false))
    @StateObject var allCTBugAppsHidden = toggleState(state: isAllCTBugAppsHidden())
    
    @Binding var colorScheme: Int
    
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
                        Haptic.shared.play(.light)
                        withAnimation(niceAnimation) {
                            showOptions = false
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
                            Group {
                                Toggle(isOn: $tweakEnable, label: {
                                    Label(
                                        title: { Text("Tweak Enable") },
                                        icon: { Image(systemName: "wrench.and.screwdriver") }
                                    )
                                })
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
                                    DispatchQueue.main.async {
                                        let newStatus = (obj.object as! NSNumber).boolValue
                                        opensshStatus.state = newStatus
                                    }
                                }
                                if isBootstrapInstalled() {
                                    Toggle(isOn: Binding(get: {allowURLSchemes.state}, set: {
                                        allowURLSchemes.state = $0
                                        URLSchemesAction($0)
                                    }), label: {
                                        Label(
                                            title: { Text("URL Schemes") },
                                            icon: { Image(systemName: "link") }
                                        )
                                    })
                                    .disabled(!isSystemBootstrapped())
                                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("URLSchemesCancelNotification"))) { obj in
                                        DispatchQueue.main.async {
                                            allowURLSchemes.state = false
                                        }
                                    }
                                }
                                HStack {
                                    Label(
                                        title: { Text("Colors") },
                                        icon: { Image(systemName: "paintpalette") }
                                    )
                                    Spacer()
                                    Picker(selection: $colorScheme, label: Text("")) {
                                        Text("Warm").tag(0)
                                        Text("Cold").tag(1)
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                            .padding(5)
                            
                            Divider().padding(10)
                            
                            VStack(alignment: .leading, spacing: 12, content: {
                                
                                Button {
                                    Haptic.shared.play(.light)
                                    respringAction()
                                } label: {
                                    Label(
                                        title: { Text("Respring") },
                                        icon: { Image(systemName: "arrow.clockwise") }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor((!isSystemBootstrapped() || !checkBootstrapVersion()) ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                }
                                .frame(width: 250)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.gray, lineWidth: 1)
                                        .opacity(0.3)
                                )
                                .disabled(!isSystemBootstrapped() || !checkBootstrapVersion())
                                
                                Button {
                                    Haptic.shared.play(.light)
                                    rebuildappsAction()
                                } label: {
                                    Label(
                                        title: { Text("Rebuild Apps") },
                                        icon: { Image(systemName: "arrow.clockwise") }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor((!isSystemBootstrapped() || !checkBootstrapVersion()) ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                }
                                .frame(width: 250)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.gray, lineWidth: 1)
                                        .opacity(0.3)
                                )
                                .disabled(!isSystemBootstrapped() || !checkBootstrapVersion())
                                
                                Button {
                                    Haptic.shared.play(.light)
                                    rebuildIconCacheAction()
                                } label: {
                                    Label(
                                        title: { Text("Rebuild Icon Cache") },
                                        icon: { Image(systemName: "arrow.clockwise") }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor((!isSystemBootstrapped() || !checkBootstrapVersion()) ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                }
                                .frame(width: 250)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.gray, lineWidth: 1)
                                        .opacity(0.3)
                                )
                                .disabled(!isSystemBootstrapped() || !checkBootstrapVersion())
                                
                                if isSystemBootstrapped() && checkBootstrapVersion()
                                {
                                    if FileManager.default.fileExists(atPath: jbroot("/basebin/.launchctl_support"))
                                    {
                                        Button {
                                            Haptic.shared.play(.light)
                                            rebootUserspaceAction();
                                        } label: {
                                            Label(
                                                title: { Text("Reboot Userspace") },
                                                icon: { Image(systemName: "arrow.clockwise.circle") }
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .foregroundColor((!isSystemBootstrapped() || !checkBootstrapVersion()) ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                        }
                                        .frame(width: 250)
                                        .background(Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.gray, lineWidth: 1)
                                                .opacity(0.3)
                                        )
                                    }
                                    else
                                    {
                                        Button {
                                            Haptic.shared.play(.light)
                                            if isAllCTBugAppsHidden() {
                                                unhideAllCTBugApps()
                                            } else {
                                                hideAllCTBugApps()
                                            }
                                        } label: {
                                            Label(
                                                title: { Text( allCTBugAppsHidden.state && isAllCTBugAppsHidden() ? "Unhide Jailbreak Apps" : "Hide All JB/TS Apps") },
                                                icon: { Image(systemName: "arrow.clockwise.circle") }
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .foregroundColor((!isSystemBootstrapped() || !checkBootstrapVersion()) ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                        }
                                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("unhideAllCTBugAppsNotification"))) { obj in
                                            DispatchQueue.main.async {
                                                allCTBugAppsHidden.state = isAllCTBugAppsHidden()
                                            }
                                        }
                                        .frame(width: 250)
                                        .background(Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.gray, lineWidth: 1)
                                                .opacity(0.3)
                                        )
                                    }
                                }
                                
                                Button {
                                    Haptic.shared.play(.light)
                                    resetMobilePassword()
                                } label: {
                                    Label(
                                        title: { Text("Reset Mobile Password") },
                                        icon: { Image(systemName: "key") }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor((!isSystemBootstrapped() || !checkBootstrapVersion()) ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                }
                                .frame(width: 250)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.gray, lineWidth: 1)
                                        .opacity(0.3)
                                )
                                .disabled(!isSystemBootstrapped() || !checkBootstrapVersion())
                                
                                Button {
                                    Haptic.shared.play(.light)
                                    reinstallPackageManager()
                                } label: {
                                    Label(
                                        title: { Text("Reinstall Sileo & Zebra") },
                                        icon: { Image(systemName: "shippingbox") }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor((!isSystemBootstrapped() || !checkBootstrapVersion()) ? Color.accentColor : Color.init(uiColor: UIColor.label))
                                }
                                .frame(width: 250)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.gray, lineWidth: 1)
                                        .opacity(0.3)
                                )
                                .disabled(!isSystemBootstrapped() || !checkBootstrapVersion())
                                
                                if isBootstrapInstalled() {
                                    Button {
                                        Haptic.shared.play(.light)
                                        unbootstrapAction()
                                    } label: {
                                        Label(
                                            title: { Text("Uninstall") },
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
                        .frame(width: 253)
                        .padding(20)
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(20)
                                .opacity(0.5)
                        }
                    }
                }
            }
            .frame(maxHeight: 650)
            .scaleEffect(showOptions ? 1 : 0.9)
        }
    }
}


