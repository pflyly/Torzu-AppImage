# Torzu-AppImage-Optimized-for-Steamdeck

This repository makes builds with several flags of optimization especially for **Steamdeck**.

The **PGO** optimization Build is built locally via Torzu_PGO_maker.sh script(which can be found in this repo) on a Steamdeck Oled, cmake code is from [citron](https://git.citron-emu.org/Citron/Citron/commit/d869045b77fc31f8555b04590b8982c4196bbd83) .

Due to the complexity of PGO two phase building, it can't be built automatically through CI for now.


* [Latest Normal Release](https://github.com/pflyly/Torzu-AppImage/releases)
* [Latest PGO_Optimized Release](https://github.com/pflyly/Torzu-AppImage/releases/tag/PGO_Optimized)


---------------------------------------------------------------

Is this fork, AppImage made using torzu official AppImage-build.sh directly instead of upstream using [sharun](https://github.com/VHSgunzo/sharun).

**This AppImage aim only for Steamdeck, so we don't need to bundle every lib, which can keep the final appimage as small as possible.**


**It also uses the [uruntime](https://github.com/VHSgunzo/uruntime) which makes use of dwarfs, resulting in a smaller and faster AppImage.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend this alternative instead: https://github.com/ivan-hc/AM

This appimage works without fuse2 as it can use fuse3 instead.
