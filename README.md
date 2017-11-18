# Simple Comic
Simple Comic is a streamlined comic viewer for OS-X.

The basic feature drive is to reduce the number of interactions required to browse a comic.

Quick Comic is a bundled quicklook preview and thumbnail generation plugin for cbr and cbz files.

## Build

For this to build you need to get the submodules. For that you need to run the following commands.

```
git submodule init
git submodule sync
git submodule update
```

### NOTICE
The newest XADMaster might lack support for RAR for the time being, if this is a problem you encounter, and you want to keep using RAR do the following:

1. Go into Vendor/XADMaster in a terminal and run this: 
```
git checkout fe62093f62dc6dd3f944d7ffb57f677822009940
```
2. Remove reference to XADPMArc1Handle.h and XADPMArc1Handle.m

Hopefully the RAR issue will be fixed in our XADMaster soon.
