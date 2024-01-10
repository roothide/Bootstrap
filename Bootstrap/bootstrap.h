#ifndef bootstrap_h
#define bootstrap_h

#define BOOTSTRAP_VERSION   (5)

void rebuildSignature(NSString *directoryPath);

int bootstrap();

int unbootstrap();

bool isBootstrapInstalled();

bool isSystemBootstrapped();

bool checkBootstrapVersion();

#endif /* bootstrap_h */
