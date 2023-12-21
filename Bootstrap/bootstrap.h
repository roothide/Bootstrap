#ifndef bootstrap_h
#define bootstrap_h


void rebuildSignature(NSString *directoryPath);

int bootstrap();

int unbootstrap();

bool isBootstrapInstalled();

bool isSystemBootstrapped();


#endif /* bootstrap_h */
