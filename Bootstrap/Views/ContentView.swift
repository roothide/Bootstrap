//
//  ContentView.swift
//  BootstrapUI
//
//  Created by haxi0 on 21.12.2023.
//

import SwiftUI
import FluidGradient

@objc class SwiftUIViewWrapper: NSObject {
    @objc static func createSwiftUIView() -> UIViewController {
        let viewController = UIHostingController(rootView: MainView())
        return viewController
    }
}

public let niceAnimation = Animation.timingCurve(0.25, 0.1, 0.35, 1.3).speed(0.9)

struct MainView: View {
    @State var LogItems: [String.SubSequence] = {
        return [""]
    }()
    
//    let colorsWarm: [Color] = [.red, .orange, .yellow]
//    let colorsCold: [Color] = [.blue, .purple, .pink]
    
    @State var currentBlobs: [Color] = []
    @State var currentHighlights: [Color] = []
    
    @AppStorage("colorScheme") var colorScheme = 0
    
    @State private var showOptions = false
    @State private var showCredits = false
    @State private var showAppView = false
    @State private var strapButtonDisabled = false
    @State private var newVersionAvailable = false
    @State private var newVersionReleaseURL:String = ""
    @State private var tweakEnable: Bool = !isSystemBootstrapped() || FileManager.default.fileExists(atPath: jbroot("/var/mobile/.tweakenabled"))
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    var body: some View {
        ZStack {
            FluidGradient(blobs: currentBlobs,
                          highlights: currentHighlights,
                          speed: 0.5,
                          blur: 0.95)
            .background(.quaternary)
            .ignoresSafeArea()
            .onAppear {
                currentBlobs = colorScheme == 0 ? [.red, .orange] : [.blue, .purple]
                currentHighlights = colorScheme == 0 ? [.red, .yellow] : [.blue, .pink]
            }
            .onChange(of: colorScheme) {_ in
                withAnimation(.easeInOut(duration: 2.5).speed(0.5)) {
                    currentBlobs = colorScheme == 0 ? [.red, .orange] : [.blue, .purple]
                    currentHighlights = colorScheme == 0 ? [.red, .yellow] : [.blue, .pink]
                }
            }
            
            VStack {
                HStack(spacing: 15) {
                    Image("Bootstrap")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                    
                    VStack(alignment: .leading, content: {
                        Text("Bootstrap")
                            .bold()
                            .font(Font.system(size: 35))
                        Text("Version \(appVersion!)")
                            .font(Font.system(size: 20))
                            .opacity(0.5)
                    })
                }
                .padding(20)
                
                if newVersionAvailable {
                    Button {
                        UIApplication.shared.open(URL(string: newVersionReleaseURL)!)
                    } label: {
                        Label(
                            title: { Text("New Version Available") },
                            icon: { Image(systemName: "arrow.down.app.fill") }
                        )
                    }
                    .frame(height:20)
                    .padding(.top, -20)
                    .padding(10)
                }
                
                VStack {
                    Button {
                        Haptic.shared.play(.light)
                        bootstrapAction()
                    } label: {
                        if isSystemBootstrapped() {
                            if checkBootstrapVersion() {
                                Label(
                                    title: { Text("Bootstrapped").bold() },
                                    icon: { Image(systemName: "chair.fill") }
                                )
                                .frame(maxWidth: .infinity)
                                .padding(25)
                                .onAppear() {
                                    strapButtonDisabled = true
                                }
                            } else {
                                Label(
                                    title: { Text("Update").bold() },
                                    icon: { Image(systemName: "chair") }
                                )
                                .frame(maxWidth: .infinity)
                                .padding(25)
                            }
                        } else if isBootstrapInstalled() {
                            Label(
                                title: { Text("Bootstrap").bold() },
                                icon: { Image(systemName: "chair") }
                            )
                            .frame(maxWidth: .infinity)
                            .padding(25)
                        } else if ProcessInfo.processInfo.operatingSystemVersion.majorVersion>=15 {
                            Label(
                                title: { Text("Install").bold() },
                                icon: { Image(systemName: "chair") }
                            )
                            .frame(maxWidth: .infinity)
                            .padding(25)
                        } else {
                            Label(
                                title: { Text("Unsupported").bold() },
                                icon: { Image(systemName: "chair") }
                            )
                            .frame(maxWidth: .infinity)
                            .padding(25)
                            .onAppear() {
                                strapButtonDisabled = true
                            }
                        }
                    }
                    .frame(width: 295)
                    .background {
                        Color(UIColor.systemBackground)
                            .cornerRadius(18)
                            .opacity(0.5)
                    }
                    .disabled(strapButtonDisabled)
                    
                    HStack {
                        
                        Button {
                            showAppView.toggle()
                            Haptic.shared.play(.light)
                        } label: {
                            Label(
                                title: { Text("App List") },
                                icon: { Image(systemName: "checklist") }
                            )
                            .frame(width: 145, height: 65)
                        }
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(18)
                                .opacity(0.5)
                        }
                        .disabled(!isSystemBootstrapped() || !checkBootstrapVersion())
                        
                        Button {
                            withAnimation(niceAnimation) {
                                Haptic.shared.play(.light)
                                showOptions = true
                            }
                        } label: {
                            Label(
                                title: { Text("Settings") },
                                icon: { Image(systemName: "gear") }
                            )
                            .frame(width: 145, height: 65)
                        }
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(18)
                                .opacity(0.5)
                        }
                        
                    }
                    
                    VStack {
                        ScrollView {
                            ScrollViewReader { scroll in
                                VStack(alignment: .leading) {
                                    ForEach(0..<LogItems.count, id: \.self) { LogItem in
                                        Text("\(String(LogItems[LogItem]))")
                                            .textSelection(.enabled)
                                            .font(.custom("Menlo", size: 15))
                                            .foregroundColor(.white)
                                    }
                                }
                                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LogMsgNotification"))) { obj in
                                    DispatchQueue.global(qos: .utility).async {
                                        LogItems.append((obj.object as! NSString) as String.SubSequence)
                                        scroll.scrollTo(LogItems.count - 1)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .frame(width: 253)
                    .padding(20)
                    .background {
                        Color(.black)
                            .cornerRadius(18)
                            .opacity(0.5)
                    }
                    
                    Text("UI made with love by haxi0. ♡")
                        .font(Font.system(size: 13))
                        .opacity(0.5)
                }
            }
            .scaleEffect((showOptions || showCredits) ? 0.9 : 1)
        }
        .tint(colorScheme == 0 ? .orange : .blue)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                withAnimation(niceAnimation) {
                    Haptic.shared.play(.light)
                    showCredits.toggle()
                }
            } label: {
                Label(
                    title: { Text("Credits") },
                    icon: { Image(systemName: "person") }
                )
            }
            .frame(height:30, alignment: .bottom)
            .padding(10)
            .animation(.default, value: colorScheme)
            .tint(colorScheme == 0 ? .orange : .blue)
        }
        .overlay {
            Group {
                CreditsView(showCredits: $showCredits)
                    .opacity(showCredits ? 1 : 0)
                    .allowsHitTesting(showCredits)
                OptionsView(showOptions: $showOptions, tweakEnable: $tweakEnable, colorScheme: $colorScheme)
                    .opacity(showOptions ? 1 : 0)
                    .allowsHitTesting(showOptions)
            }
            .animation(.default, value: colorScheme)
            .tint(colorScheme == 0 ? .orange : .blue)
        }
        .onAppear {
            initFromSwiftUI()
            Task {
                do {
                    try await checkForUpdates()
                } catch {

                }
            }
        }
        .sheet(isPresented: $showAppView) {
            AppViewControllerWrapper()
        }
    }
    
    func checkForUpdates() async throws {
        if let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let owner = "roothide"
            let repo = "Bootstrap"
            
            // Get the releases
            let releasesURL = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases")!
            let releasesRequest = URLRequest(url: releasesURL)
            let (releasesData, _) = try await URLSession.shared.data(for: releasesRequest)
            guard let releasesJSON = try JSONSerialization.jsonObject(with: releasesData, options: []) as? [[String: Any]] else {
                return
            }
            
            if let latestTag = releasesJSON.first?["tag_name"] as? String, latestTag != currentAppVersion {
                newVersionAvailable = true
                newVersionReleaseURL = "https://github.com/\(owner)/\(repo)/releases/tag/\(latestTag)"
            }
        }
    }
}

struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
