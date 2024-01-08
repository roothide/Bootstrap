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
        let viewController = UIHostingController(rootView: ContentView())
        return viewController
    }
}

struct ContentView: View {
    @State var LogItems: [String.SubSequence] = {
        return [""]
    }()
    
    @State private var openSSH = false
    @State private var showOptions = false
    @State private var showCredits = false
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    var body: some View {
        ZStack {
            FluidGradient(blobs: [.red, .orange],
                          highlights: [.red, .yellow],
                          speed: 0.5,
                          blur: 0.95)
            .background(.quaternary)
            
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
                
                VStack {
                    Button {
                        bootstrapFr()
                    } label: {
                        if isBootstrapInstalled() {
                            Label(
                                title: { Text("Kickstart").bold() },
                                icon: { Image(systemName: "terminal") }
                            )
                            .padding(25)
                        } else {
                            Label(
                                title: { Text("Bootstrap").bold() },
                                icon: { Image(systemName: "terminal") }
                            )
                            .padding(25)
                        }
                    }
                    .frame(width: 295)
                    .background {
                        Color(UIColor.systemBackground)
                            .cornerRadius(20)
                            .opacity(0.5)
                    }
                    .disabled(isSystemBootstrapped())
                    
                    if isBootstrapInstalled() {
                        Button {
                            unbootstrapFr()
                        } label: {
                            Label(
                                title: { Text("Uninstall").bold() },
                                icon: { Image(systemName: "trash") }
                            )
                            .padding(25)
                        }
                        .frame(width: 295)
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(20)
                                .opacity(0.5)
                        }
                        .disabled(isSystemBootstrapped())
                    }
                    
                    HStack {
                        Button {
                            withAnimation {
                                showOptions.toggle()
                            }
                        } label: {
                            Label(
                                title: { Text("Settings") },
                                icon: { Image(systemName: "gear") }
                            )
                            .padding(25)
                        }
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(20)
                                .opacity(0.5)
                        }
                        .disabled(!isSystemBootstrapped())
                        
                        Button {
                            respringFr()
                        } label: {
                            Label(
                                title: { Text("Respring") },
                                icon: { Image(systemName: "arrow.clockwise") }
                            )
                            .padding(25)
                        }
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(20)
                                .opacity(0.5)
                        }
                        .disabled(!isSystemBootstrapped())
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
                                .onReceive(NotificationCenter.default.publisher(for: LogStream.shared.reloadNotification)) { obj in
                                    DispatchQueue.global(qos: .utility).async {
                                        FetchLog()
                                        scroll.scrollTo(LogItems.count - 1)
                                    }
                                }
                            }
                        }
                        .frame(height: 150)
                    }
                    .frame(width: 253)
                    .padding(20)
                    .background {
                        Color(.black)
                            .cornerRadius(20)
                            .opacity(0.5)
                    }
                    
                    Text("UI made with love by haxi0. ♡")
                        .font(Font.system(size: 13))
                        .opacity(0.5)
                }
            }
            
            Button {
                withAnimation {
                    showCredits.toggle()
                }
            } label: {
                Label(
                    title: { Text("Credits") },
                    icon: { Image(systemName: "person") }
                )
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(25)
        }
        .ignoresSafeArea()
        .overlay {
            if showCredits {
                CreditsView(showCredits: $showCredits)
            }
            
            if showOptions {
                OptionsView(showOptions: $showOptions, openSSH: $openSSH)
            }
        }
        .onAppear {
            if isSystemBootstrapped() {
                checkServerFr()
            }
        }
    }
    
    private func FetchLog() {
        guard let AttributedText = LogStream.shared.outputString.copy() as? NSAttributedString else {
            LogItems = ["Error Getting Log!"]
            return
        }
        LogItems = AttributedText.string.split(separator: "\n")
    }
}
