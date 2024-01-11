#ifndef sources_h
#define sources_h

#define DEFAULT_SOURCES "\
Types: deb\n\
URIs: https://repo.chariz.com/\n\
Suites: ./\n\
Components:\n\
\n\
Types: deb\n\
URIs: https://havoc.app/\n\
Suites: ./\n\
Components:\n\
\n\
Types: deb\n\
URIs: http://apt.thebigboss.org/repofiles/cydia/\n\
Suites: stable\n\
Components: main\n\
\n\
Types: deb\n\
URIs: https://roothide.github.io/\n\
Suites: ./\n\
Components:\n\
\n\
Types: deb\n\
URIs: https://roothide.github.io/procursus\n\
Suites: iphoneos-arm64e/%d\n\
Components: main\n\
\n\
Types: deb\n\
URIs: https://34306.github.io/\n\
Suites: ./\n\
Components:\n\
\n\
Types: deb\n\
URIs: https://bvn-roothide.github.io/\n\
Suites: ./\n\
Components:\n\
"

#define ALT_SOURCES "\
Types: deb\n\
URIs: https://iosjb.top/\n\
Suites: ./\n\
Components:\n\
\n\
Types: deb\n\
URIs: https://iosjb.top/procursus\n\
Suites: iphoneos-arm64e/%d\n\
Components: main\n\
"

#define ZEBRA_SOURCES "\
# Zebra Sources List\n\
deb https://getzbra.com/repo/ ./\n\
deb https://repo.chariz.com/ ./\n\
deb https://havoc.app/ ./\n\
deb https://roothide.github.io/ ./\n\
deb https://roothide.github.io/procursus iphoneos-arm64e/%d main\n\
deb https://wwg135.github.io/ ./\n\
\n\
"

#endif /* sources_h */
