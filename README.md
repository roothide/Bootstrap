# Bootstrap
[![Build and Package](https://github.com/RootHide/Bootstrap/actions/workflows/package.yml/badge.svg)](https://github.com/RootHide/Bootstrap/actions/workflows/package.yml)  
A full featured bootstrap for ios16.0~17.0 (A12+)

# How To Build

 1. Update your theos to the this

    ```git clone --recursive https://github.com/roothide/theos.git ```
    
    or
    
    ```bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)"```
    
    this theos is always automatically updated to latest with the upstream.

 3. Build tipa

    ```make package```

then get Bootstrap.tipa in /packages/ and install it in trollstore.

