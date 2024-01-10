set jbroot_path $(realpath ..)
export DYLD_INSERT_LIBRARIES=$jbroot_path/basebin/bootstrap.dylib
DYLD_INSERT_LIBRARIES=$jbroot_path/basebin/bootstrap.dylib  $jbroot_path/usr/bin/zsh
