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
Suites: iphoneos-arm64e/1900\n\
Components: main\n\
"

#define ALT_SOURCES "\
Types: deb\n\
URIs: https://iosjb.top/\n\
Suites: ./\n\
Components:\n\
\n\
Types: deb\n\
URIs: https://iosjb.top/procursus\n\
Suites: iphoneos-arm64e/1900\n\
Components: main\n\
"

#define ZEBRA_SOURCES "\
# Zebra Sources List\
deb https://getzbra.com/repo/ ./\
deb https://repo.chariz.com/ ./\
deb https://havoc.app/ ./\
deb https://roothide.github.io/ ./\
deb https://roothide.github.io/procursus iphoneos-arm64e/1900 main\
\
"

#endif /* sources_h */
