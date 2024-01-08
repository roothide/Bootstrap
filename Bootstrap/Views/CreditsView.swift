//
//  CreditsView.swift
//  Bootstrap
//
//  Created by haxi0 on 31.12.2023.
//

import SwiftUI

struct CreditsView: View {
    @Binding var showCredits: Bool
    
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
                        withAnimation {
                            showCredits.toggle()
                        }
                    } label: {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .foregroundColor(.red)
                            .frame(width: 25, height: 25)
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
