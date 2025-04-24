# Torzu & Sudachi AppImage Optimized for Steamdeck

[![GitHub Release](https://img.shields.io/badge/Sudachi-v1.0.15-blue?label=Sudachi%20Release)](https://github.com/pflyly/Torzu-sudachi-AppImage/releases/tag/Sudachi-v1.0.15)
[![GitHub Release](https://img.shields.io/github/v/release/pflyly/Torzu-sudachi-AppImage?label=Torzu%20Release)](https://github.com/pflyly/Torzu-sudachi-AppImage/releases/latest)
[![GitHub Downloads](https://img.shields.io/github/downloads/pflyly/Torzu-sudachi-AppImage/total?logo=github&label=GitHub%20Downloads)](https://github.com/pflyly/Torzu-sudachi-AppImage/releases)
[![CI Build Status](https://github.com//pflyly/Torzu-sudachi-AppImage/actions/workflows/sudachi.yml/badge.svg)](https://github.com/pflyly/Torzu-sudachi-AppImage/actions/workflows/sudachi.yml)
[![CI Build Status](https://github.com//pflyly/Torzu-sudachi-AppImage/actions/workflows/torzu.yml/badge.svg)](https://github.com/pflyly/Torzu-sudachi-AppImage/actions/workflows/torzu.yml)


This repository makes builds with several flags of optimization especially for **Steamdeck**.

* [Latest Torzu Release](https://github.com/pflyly/Torzu-sudachi-AppImage/releases/latest)
* [Latest Sudachi Release](https://github.com/pflyly/Torzu-sudachi-AppImage/releases/tag/Sudachi-v1.0.15)

---------------------------------------------------------------

In this fork, the Torzu and Sudachi Appimage are made using modified appimage-builder.sh of [Citron](https://git.citron-emu.org/Citron/Citron/src/branch/master/appimage-builder.sh) directly instead of upstream using [sharun](https://github.com/VHSgunzo/sharun).

**It also uses the [uruntime](https://github.com/VHSgunzo/uruntime) which makes use of dwarfs, resulting in a smaller and faster AppImage.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend this alternative instead: https://github.com/ivan-hc/AM

This appimage works without fuse2 as it can use fuse3 instead.
