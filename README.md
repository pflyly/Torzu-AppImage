# Torzu-AppImage-Optimized-for-Steamdeck

This repository makes builds with several flags of optimization especially for **Steamdeck**.

Another **PGO** optimization Build will be built locally via Citron_PGO_maker.sh script(which can be found in this repo) on a Steamdeck Oled and add to the relase page manually.

Due the complexity of PGO two phase building, it can't be built automatically through CI for now.

* [Latest Nightly Release](https://github.com/pflyly/Citron-AppImage/releases/tag/nightly)
* [Latest Stable Release](https://github.com/pflyly/Citron-AppImage/releases/latest)

---------------------------------------------------------------

AppImage made using [sharun](https://github.com/VHSgunzo/sharun), which makes it extremely easy to turn any binary into a portable package without using containers or similar tricks.

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

**It also uses the [uruntime](https://github.com/VHSgunzo/uruntime) which makes use of dwarfs, resulting in a smaller and faster AppImage.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend this alternative instead: https://github.com/ivan-hc/AM

This appimage works without fuse2 as it can use fuse3 instead.
