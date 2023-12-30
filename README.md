# Bootstrap
[![GitHub stars](https://img.shields.io/github/stars/RootHide/Bootstrap?style=social)](https://github.com/RootHide/Bootstrap/stargazers)


A full featured bootstrap for ios14.0-17.0, A8-A17,M1+M2. (currently tested on ios15.0~ios17.0)

## Building

You'll need MacOS to build, as you require Xcode Command Line Tools. If you don't have Xcode installed, you can install the Command Line Tools by itself by running `xcode-select --install`.

 1. Update your theos to the this
    
    ```bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)"```
    
    This build of Theos is consistently updated.

 2. Build `Bootstrap.tipa`

    ```make package```

 3. Transfer `Bootstrap.tipa` from `./packages/` to your device and install it with TrollStore!

## Usage

Once you open the Bootstrap app, press Bootstrap. This will install the necessary apps and files.

You can add various sources to Sileo or Zebra, and install tweaks. You may need to convert tweaks to be Bootstrap compatible.

By default, tweaks are not injected into any apps. To enable tweak injection, click AppEnabler in the Bootstrap app, and toggle on an app you want to enable your tweaks in. You *cannot* inject into SpringBoard (com.apple.springboard) or Photos (com.apple.mobileslideshow) at the moment.

## Develop tweaks

[Document](https://github.com/RootHide/Developer)

## <a id="faq-convert" /> How to install tweaks?

Bootstrap can enable tweaks for almost all apps, but it does not yet support springboard tweaks, such as the homescreen, lockscreen, control center, statusbar tweaks.

When installing a tweak, you might see a message saying 'Not Updated'. This tweak will need to be updated to support Bootstrap.

Install the Patcher in the sileo. When attempting to install a tweak, press 'Convert'. In the share sheet, press the Patcher app. When you convert a tweak to be Bootstrap compatible, you're given the option to directly convert simple tweaks or use rootless compat layer. If a tweak doesn't work with directly converting, try the rootless compat layer! You will need to install rootless-compat as a dependancy.

## <a id="faq-discord" /> I have a question that isn't listed here. Where do I go for help?

You can join the our Discord [here](https://discord.com/invite/scqCkumAYp).

## Credits

Huge thanks to these people, we couldn't have completed this project without their help!

- absidue: [https://github.com/absidue](https://github.com/absidue)
- akusio: [https://twitter.com/akusio_rr](https://twitter.com/akusio_rr)
- Alfie: [https://alfiecg.uk](https://alfiecg.uk)
- Amy While: [http://github.com/elihwyma](http://github.com/elihwyma)
- Barron: [https://tweaksdev22.github.io](https://tweaksdev22.github.io)
- BomberFish: [https://twitter.com/bomberfish77](https://twitter.com/bomberfish77)
- bswbw: [https://twitter.com/bswbw](https://twitter.com/bswbw)
- Capt Inc: [http://github.com/captinc](http://github.com/captinc)
- CKatri: [https://procursus.social/@cameron](https://procursus.social/@cameron)
- Clarity: [http://github.com/TheRealClarity](http://github.com/TheRealClarity)
- Cryptic: [http://github.com/Cryptiiiic](http://github.com/Cryptiiiic)
- dxcool223x: [https://twitter.com/dxcool223x](https://twitter.com/dxcool223x)
- Dhinakg: [http://github.com/dhinakg](http://github.com/dhinakg)
- DuyKhanhTran: [https://twitter.com/TranKha50277352](https://twitter.com/TranKha50277352)
- dleovl: [https://github.com/dleovl](https://github.com/dleovl)
- Elias Sfeir: [https://twitter.com/eliassfeir1](https://twitter.com/eliassfeir1)
- Ellie: [https://twitter.com/elliessurviving](https://twitter.com/elliessurviving)
- EquationGroups: [https://twitter.com/equationgroups](https://twitter.com/equationgroups)
- Évelyne: [http://github.com/evelyneee](http://github.com/evelyneee)
- GeoSnOw: [https://twitter.com/fce365](https://twitter.com/fce365)
- G3n3sis: [https://twitter.com/G3nNuk_e](https://twitter.com/G3nNuk_e)
- hayden: [https://procursus.social/@hayden](https://procursus.social/@hayden)
- Huy Nguyen: [https://twitter.com/little_34306](https://twitter.com/little_34306)
- iAdam1n: [https://twitter.com/iAdam1n](https://twitter.com/iAdam1n)
- iarrays: [https://iarrays.com](https://iarrays.com)
- iDownloadBlog: [https://twitter.com/idownloadblog](https://twitter.com/idownloadblog)
- iExmo: [https://twitter.com/iexmojailbreak](https://twitter.com/iexmojailbreak)
- iRaMzi: [https://twitter.com/iramzi7](https://twitter.com/iramzi7)
- Jonathan: [https://twitter.com/jontelang](https://twitter.com/jontelang)
- Kevin: [https://github.com/iodes](https://github.com/iodes)
- kirb: [http://github.com/kirb](http://github.com/kirb)
- laileld: [https://twitter.com/h_h_x_t](https://twitter.com/h_h_x_t)
- Leptos: [https://github.com/leptos-null](https://github.com/leptos-null)
- limneos: [https://twitter.com/limneos](https://twitter.com/limneos)
- Lightmann: [https://github.com/L1ghtmann](https://github.com/L1ghtmann)
- Linus Henze: [http://github.com/LinusHenze](http://github.com/LinusHenze)
- MasterMike: [https://ios.cfw.guide](https://ios.cfw.guide)
- Misty: [https://twitter.com/miscmisty](https://twitter.com/miscmisty)
- Muirey03: [https://twitter.com/Muirey03](https://twitter.com/Muirey03)
- Nathan: [https://github.com/verygenericname](https://github.com/verygenericname)
- Nebula: [https://itsnebula.net](https://itsnebula.net)
- niceios: [https://twitter.com/niceios](https://twitter.com/niceios)
- Nightwind: [https://twitter.com/NightwindDev](https://twitter.com/NightwindDev)
- Nick Chan: [https://nickchan.lol](https://nickchan.lol)
- nzhaonan: [https://twitter.com/nzhaonan](https://twitter.com/nzhaonan)
- omrkujman: [https://twitter.com/omrkujman](https://twitter.com/omrkujman)
- opa334: [http://github.com/opa334](http://github.com/opa334)
- onejailbreak: [https://twitter.com/onejailbreak_](https://twitter.com/onejailbreak_)
- Phuc Do: [https://twitter.com/dobabaophuc](https://twitter.com/dobabaophuc)
- PoomSmart: [https://twitter.com/poomsmart](https://twitter.com/poomsmart)
- ProcursusTeam: [https://procursus.social/@team](https://procursus.social/@team)
- roothide: [http://github.com/RootHide](http://github.com/RootHide)
- Sam Bingner: [http://github.com/sbingner](http://github.com/sbingner)
- Shadow-: [http://iosjb.top/](http://iosjb.top/)
- Snail: [https://twitter.com/somnusix](https://twitter.com/somnusix)
- SquidGesture: [https://twitter.com/lclrc](https://twitter.com/lclrc)
- sourcelocation: [http://github.com/sourcelocation](http://github.com/sourcelocation)
- SeanIsTethered: [http://github.com/jailbreakmerebooted](https://github.com/jailbreakmerebooted)
- TheosTeam: [https://theos.dev](https://theos.dev)
- tigisoftware: [https://twitter.com/tigisoftware](https://twitter.com/tigisoftware)
- tihmstar: [https://twitter.com/tihmstar](https://twitter.com/tihmstar)
- xina520: [https://twitter.com/xina520](https://twitter.com/xina520)
- xybp888: [https://twitter.com/xybp888](https://twitter.com/xybp888)
- xsf1re: [https://twitter.com/xsf1re](https://twitter.com/xsf1re)
- yandevelop: [https://twitter.com/yandevelop](https://twitter.com/yandevelop)
- YourRepo: [https://twitter.com/yourepo](https://twitter.com/yourepo)
