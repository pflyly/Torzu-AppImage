# Torzu & Sudachi AppImage Optimized for Steamdeck

This repository makes builds with several flags of optimization especially for **Steamdeck**.

* [Latest Torzu Release](https://github.com/pflyly/Torzu-sudachi-AppImage/releases/tag/Torzu)
* [Latest Sudachi Release](https://github.com/pflyly/Torzu-sudachi-AppImage/releases/tag/Sudachi)

---------------------------------------------------------------

In this fork, the Torzu AppImage is made using torzu official AppImage-build.sh, and Sudachi Appimage is made using modified appimage-builder.sh of [Citron](https://git.citron-emu.org/Citron/Citron/src/branch/master/appimage-builder.sh) directly instead of upstream using [sharun](https://github.com/VHSgunzo/sharun).

**It also uses the [uruntime](https://github.com/VHSgunzo/uruntime) which makes use of dwarfs, resulting in a smaller and faster AppImage.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend this alternative instead: https://github.com/ivan-hc/AM

This appimage works without fuse2 as it can use fuse3 instead.
