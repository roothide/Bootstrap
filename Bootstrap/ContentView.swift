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
        let viewController = UIHostingController(rootView: SwiftUIView())
        return viewController
    }
}

struct ContentView: View {
    // init console base text
    @State var LogItems: [String.SubSequence] = {
        return [""]
    }()
    
    let credits: [String: String] = [
        "opa334": "http://github.com/opa334",
        "hayden": "https://procursus.social/@hayden",
        "CKatri": "https://procursus.social/@cameron",
        "Alfie": "https://alfiecg.uk",
        "BomberFish": "https://twitter.com/bomberfish77",
        "Évelyne": "http://github.com/evelyneee",
        "sourcelocation": "http://github.com/sourcelocation",
        "Linus Henze": "http://github.com/LinusHenze",
        "Cryptic": "http://github.com/Cryptiiiic",
        "Clarity": "http://github.com/TheRealClarity",
        "Dhinakg": "http://github.com/dhinakg",
        "Capt Inc": "http://github.com/captinc",
        "Sam Bingner": "http://github.com/sbingner",
        "ProcursusTeam": "https://procursus.social/@team",
        "TheosTeam": "https://theos.dev",
        "kirb": "http://github.com/kirb",
        "Amy While": "http://github.com/elihwyma",
        "roothide": "http://github.com/RootHide",
        "Shadow-": "http://iosjb.top/",
        "Huy Nguyen": "https://twitter.com/little_34306",
        "haxi0": "https://haxi0.space",
        "Nebula": "https://itsnebula.net",
        "DuyKhanhTran": "https://twitter.com/TranKha50277352",
        "Nathan": "https://github.com/verygenericname",
        "Nick Chan": "https://nickchan.lol",
        "Muirey03": "https://twitter.com/Muirey03",
        "absidue": "https://github.com/absidue",
        "MasterMike": "https://ios.cfw.guide",
        "Nightwind": "https://twitter.com/NightwindDev",
        "Leptos": "https://github.com/leptos-null",
        "Lightmann": "https://github.com/L1ghtmann",
        "iAdam1n": "https://twitter.com/iAdam1n",
        "xina520": "https://twitter.com/xina520",
        "Barron": "https://tweaksdev22.github.io",
        "iarrays": "https://iarrays.com",
        "niceios": "https://twitter.com/niceios",
        "Snail": "https://twitter.com/somnusix",
        "Misty": "https://twitter.com/miscmisty",
        "limneos": "https://twitter.com/limneos",
        "iDownloadBlog": "https://twitter.com/idownloadblog",
        "GeoSnOw": "https://twitter.com/fce365",
        "onejailbreak": "https://twitter.com/onejailbreak_",
        "iExmo": "https://twitter.com/iexmojailbreak",
        "omrkujman": "https://twitter.com/omrkujman",
        "nzhaonan": "https://twitter.com/nzhaonan",
        "YourRepo": "https://twitter.com/yourepo",
        "Phuc Do": "https://twitter.com/dobabaophuc",
        "dxcool223x": "https://twitter.com/dxcool223x",
        "akusio": "https://twitter.com/akusio_rr",
        "xsf1re": "https://twitter.com/xsf1re",
        "PoomSmart": "https://twitter.com/poomsmart",
        "Elias Sfeir": "https://twitter.com/eliassfeir1",
        "SquidGesture": "https://twitter.com/lclrc",
        "yandevelop": "https://twitter.com/yandevelop",
        "EquationGroups": "https://twitter.com/equationgroups",
        "tihmstar": "https://twitter.com/tihmstar",
        "laileld": "https://twitter.com/h_h_x_t",
        "bswbw": "https://twitter.com/bswbw",
        "Jonathan": "https://twitter.com/jontelang",
        "iRaMzi": "https://twitter.com/iramzi7",
        "xybp888": "https://twitter.com/xybp888",
        "Ellie": "https://twitter.com/elliessurviving",
        "tigisoftware": "https://twitter.com/tigisoftware"
    ]
    
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
                    Image("icon-1024")
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
                        print("Bootstrap Button Toggled")
                    } label: {
                        Label(
                            title: { Text("Bootstrap").bold() },
                            icon: { Image(systemName: "doc") }
                        )
                        .padding(25)
                        .foregroundColor(.red)
                    }
                    .frame(width: 295)
                    .background {
                        Color(UIColor.systemBackground)
                            .cornerRadius(20)
                            .opacity(0.5)
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
                        
                        Button {
                            print("Respring Button Toggled")
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
                                withAnimation {
                                    showCredits.toggle()
                                }
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red   )
                            }
                        }
                        
                        ScrollView {
                            VStack {
                                Text("Credits")
                                    .foregroundColor(Color(UIColor.label))
                                    .bold()
                                    .font(Font.system(size: 20))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Divider()
                                
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
                }
            }
            
            if showOptions {
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
                                    Text("Tweaks")
                                        .foregroundColor(Color(UIColor.label))
                                        .bold()
                                        .font(Font.system(size: 20))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
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
    }
    
    private func FetchLog() {
        guard let AttributedText = LogStream.shared.outputString.copy() as? NSAttributedString else {
            LogItems = ["Error Getting Log!"]
            return
        }
        LogItems = AttributedText.string.split(separator: "\n")
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
    
    private func showMsg(title: String, body: String) {
        UIApplication.shared.alert(title: title, body: body)
    }
    
    private func addLog(log: String) {
        print("[*] \(log)")
    }
}

#Preview {
    ContentView()
}
