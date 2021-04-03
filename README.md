# Virtainer
QEMU script supporting Linux, Windows and macOS guests

# History
Originally, I've made **MyFastEmulator**, which was a fork of the **quickemu** project meant to expose more configuration options and be faster. However, the code **was a mess** and I finally **abandonned it**. Not long after, I decided to start another QEMU script named **Virtainer** which would be coded from scratch using **quickemu**'s and **MyFastEmulator**'s code.

# Features
- **Full support** for **Linux, Windows and macOS guests**
- **Made around** the **latest QEMU version**
- **Very fast** and **easy to use**
- **And more!**

# NOTE about Windows 7 and legacy operating systems
Virtainer, since the April 2021 Update 1, supports Windows 7 and legacy operating systems. However, especially the Legacy optimize system option, **isn't tuned for maximum performance**. If you really want to have maximum performance in a Legacy operating system, please make a new optimize system option for your legacy operating system of choice in Virtainer's source code. For Windows 7 guests, support is limited (especially for the guest tools), like it uses a SATA drive instead of a VirtIO drive (which does waste quite some I/O performance).

# Files
**run.sh**            : The classic script, run any type of VM. (Linux, Windows and macOS)<br/>
**live-linux.sh**     : Create a Linux VM quickly for Live purposes only with a single command, both config and disk are deleted after shutdown.<br/>
**quick-linux.sh**    : Create a Linux VM quickly with a single command, both config and disk are kept after shutdown.<br/>
**config-creator.sh** : Create a config of any type. (Linux, Windows and macOS)

# Download
``git clone https://github.com/NanoSoftwares/Virtainer.git``<br/>
``cd Virtainer``

# Usage
``./config-creator.sh``<br/>
``./run.sh -vm <config>.conf``

# Create a quick Live Linux config
``./live-linux.sh <iso>``

# Create a quick Linux config
``./quick-linux.sh <iso>``
