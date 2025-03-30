# Torzu-AppImage-Optimized-for-Steamdeck

This repository makes builds with several flags of optimization especially for **Steamdeck**.

* [Latest Release](https://github.com/pflyly/Torzu-AppImage/releases/latest)

---------------------------------------------------------------

In this fork, AppImage made using torzu official AppImage-build.sh directly instead of upstream using [sharun](https://github.com/VHSgunzo/sharun).

**This AppImage aim only for Steamdeck, so we don't need to bundle every lib, which can keep the final appimage as small as possible.**


**It also uses the [uruntime](https://github.com/VHSgunzo/uruntime) which makes use of dwarfs, resulting in a smaller and faster AppImage.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend this alternative instead: https://github.com/ivan-hc/AM

This appimage works without fuse2 as it can use fuse3 instead.
