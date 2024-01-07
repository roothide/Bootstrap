# Bootstrap

[![GitHub stars](https://img.shields.io/github/stars/RootHide/Bootstrap?style=social)](https://github.com/RootHide/Bootstrap/stargazers)

A full featured bootstrap for iOS 14.0-17.0 A8-A17 & M1+M2. (Currently only tested tested on versions 15.0-17.0)

##### *WARNING:* By using this software, you take full responsibility for what you do with it. Any modification to your device may cause irreparable damage to your device.

## Building

Currently, you should build the `.tipa` file yourself, as using random `.tipa` files online (even on GitHub) can be outdated or contain malicious code. Please, do not install random `.tipa` files. You can find more information [here](https://www.reddit.com/r/jailbreak/comments/18z28qk/discussion_do_not_use_other_peoples_roothide/).

If you do not have a Mac, check the FAQ in the Usage section of this README to build with GitHub Actions.

You'll need MacOS to build, as you require Xcode. Simply having Xcode Command Line Tools is not sufficient.

You will need Homebrew installed. If you don't have Homebrew installed, run the following command: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

 1. Update your Theos to the RootHide build
    
    `bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)"`
    
    This build of Theos is consistently updated.

 2. Install make

    `brew install make`

 3. Clone the GitHub repository and enter directory

    `git clone https://github.com/RootHide/Bootstrap/ && cd Bootstrap`

 4. Build `Bootstrap.tipa`

    `gmake -j$(sysctl -n hw.ncpu) package`

 5. Transfer `Bootstrap.tipa` from `./packages/` to your device and install it with TrollStore!

## Usage

The latest version of TrollStore is required as the bootstrap is built around the CoreTrust bug. Developer mode will need to be enabled to use this bootstrap. Follow [this guide](https://docs.expo.dev/guides/ios-developer-mode/) to enable developer mode. If you do not see the option to enable developer mode, you may need to first try sideloading an application (use AltStore or Sideloadly) and the option to enable developer mode will appear.

Once you open the Bootstrap app, press Bootstrap. This will install the necessary apps and files.

You can add various sources and install tweaks through Sileo, like other jailbreaks. \You may need to convert tweaks to be Bootstrap compatible if they aren't already converted or developed for this bootstrap.

By default, tweaks are not injected into any apps. To enable tweak injection, click AppEnabler in the Bootstrap app, and toggle on an app you want to enable your tweaks in. You **cannot** inject into SpringBoard (com.apple.springboard) at the moment with official means.

A general FAQ is currently available [here](https://github.com/dleovl/RootHideBootstrapUnofficialFAQ/blob/main/README.md), though not officially affiliated with RootHide (as of writing).

## Develop tweaks

Rootful and rootless tweaks aren't out-of-the-box compatible with this bootstrap, so you'll need to develop them specifically to support it. You can refer to the developer documentation [here](https://github.com/RootHide/Developer).

## Install tweaks

Bootstrap can enable tweaks for almost all apps, but it currently does not *yet* support SpringBoard tweaks, meaning you cannot modify the homescreen, lockscreen, control center, statusbar, or anything related to the SpringBoard. While these tweaks are installable, you cannot enable SpringBoard in AppEnabler (making them useless).

When installing a tweak, you might see a message saying 'Not Updated'. This tweak will need to be updated to support the RootHide Bootstrap.

Install RootHide Patcher from *Sileo* (https://roothide.github.io/, refresh sources if it's blank!). If you have problems installing RootHide Patcher, use Sileo, as Zebra doesn't have the best compatibility for this bootstrap. When attempting to install a tweak, press 'Convert'. In the share sheet, press the Patcher app. When you convert a tweak to be Bootstrap compatible, you're given the option to directly convert simple tweaks or use rootless compat layer. Usually, you can use the rootless compat layer, but rootful tweak debs will need to be converted using a simple convert. You will need to install rootless-compat as a dependancy when converting rootless tweaks. Once the tweak is converted, press Ok and press Sileo in the share sheet. Press GET on the tweak and run the queue to install.

## Discord

You can join our Discord for support or general talk [here](https://discord.com/invite/scqCkumAYp).

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
