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
        "absidue": "https://github.com/absidue",
        "akusio": "https://twitter.com/akusio_rr",
        "Alfie": "https://alfiecg.uk",
        "Amy While": "http://github.com/elihwyma",
        "Barron": "https://tweaksdev22.github.io",
        "BomberFish": "https://twitter.com/bomberfish77",
        "bswbw": "https://twitter.com/bswbw",
        "Capt Inc": "http://github.com/captinc",
        "CKatri": "https://procursus.social/@cameron",
        "Clarity": "http://github.com/TheRealClarity",
        "Cryptic": "http://github.com/Cryptiiiic",
        "dxcool223x": "https://twitter.com/dxcool223x",
        "Dhinakg": "http://github.com/dhinakg",
        "dleovl": "https://github.com/dleovl",
        "DuyKhanhTran": "https://twitter.com/TranKha50277352",
        "Elias Sfeir": "https://twitter.com/eliassfeir1",
        "Ellie": "https://twitter.com/elliessurviving",
        "EquationGroups": "https://twitter.com/equationgroups",
        "Évelyne": "http://github.com/evelyneee",
        "GeoSnOw": "https://twitter.com/fce365",
        "G3n3sis": "https://twitter.com/G3nNuk_e",
        "Hayden": "https://procursus.social/@hayden",
        "Huy Nguyen": "https://twitter.com/little_34306",
        "iAdam1n": "https://twitter.com/iAdam1n",
        "iarrays": "https://iarrays.com",
        "iDownloadBlog": "https://twitter.com/idownloadblog",
        "iExmo": "https://twitter.com/iexmojailbreak",
        "iRaMzi": "https://twitter.com/iramzi7",
        "Jonathan": "https://twitter.com/jontelang",
        "Kevin": "https://github.com/iodes",
        "kirb": "http://github.com/kirb",
        "laileld": "https://twitter.com/h_h_x_t",
        "Leptos": "https://github.com/leptos-null",
        "limneos": "https://twitter.com/limneos",
        "Lightmann": "https://github.com/L1ghtmann",
        "Linus Henze": "http://github.com/LinusHenze",
        "MasterMike": "https://ios.cfw.guide",
        "Misty": "https://twitter.com/miscmisty",
        "Muirey03": "https://twitter.com/Muirey03",
        "Nathan": "https://github.com/verygenericname",
        "Nebula": "https://itsnebula.net",
        "niceios": "https://twitter.com/niceios",
        "Nightwind": "https://twitter.com/NightwindDev",
        "Nick Chan": "https://nickchan.lol",
        "nzhaonan": "https://twitter.com/nzhaonan",
        "omrkujman": "https://twitter.com/omrkujman",
        "opa334": "http://github.com/opa334",
        "onejailbreak": "https://twitter.com/onejailbreak_",
        "Phuc Do": "https://twitter.com/dobabaophuc",
        "PoomSmart": "https://twitter.com/poomsmart",
        "ProcursusTeam": "https://procursus.social/@team",
        "roothide": "http://github.com/RootHide",
        "Sam Bingner": "http://github.com/sbingner",
        "Shadow-": "http://iosjb.top/",
        "Snail": "https://twitter.com/somnusix",
        "SquidGesture": "https://twitter.com/lclrc",
        "sourcelocation": "http://github.com/sourcelocation",
        "SeanIsTethered": "http://github.com/jailbreakmerebooted",
        "TheosTeam": "https://theos.dev",
        "tigisoftware": "https://twitter.com/tigisoftware",
        "tihmstar": "https://twitter.com/tihmstar",
        "xina520": "https://twitter.com/xina520",
        "xybp888": "https://twitter.com/xybp888",
        "xsf1re": "https://twitter.com/xsf1re",
        "yandevelop": "https://twitter.com/yandevelop",
        "YourRepo": "https://twitter.com/yourepo"
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
