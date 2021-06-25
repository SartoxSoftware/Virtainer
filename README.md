# Virtainer
QEMU script supporting Linux, Windows and macOS guests

# History
Originally, I've made **MyFastEmulator**, which was a fork of the **quickemu** project meant to expose more configuration options and be faster. However, the code **was a mess** and I finally **abandonned it**. Not long after, I decided to start another QEMU script named **Virtainer** which would be coded from scratch using **quickemu**'s and **MyFastEmulator**'s code.

# Features
- **Full support** for **Linux, Windows and macOS guests**
- **Made around** the **latest QEMU version**
- **Very fast** and **easy to use**
- **And more!**

# NOTE about legacy operating systems
Virtainer, since the April 2021 Update 1, supports ~~Windows 7 and~~ legacy operating systems. However, this option **isn't tuned for maximum performance**. If you really want to have maximum performance in a legacy OS, please make a new optimize system option for your legacy OS of choice in Virtainer's source code.

# Files
**run.sh**            : The classic script, run any type of VM. (Linux, Windows and macOS)<br/>
**quick-linux.sh**    : Create a Linux VM quickly with a single command, both config and disk can be either kept or deleted after shutdown.<br/>
**config-creator.sh** : Create a config of any type. (Linux, Windows and macOS)<br/>
**quick-setup.sh**    : Simple script to quickly setup a Linux VM within a few minutes (or hours depending on the speed of your internet connection).

# Download
``git clone https://github.com/NanoSoftwares/Virtainer.git``<br/>
``cd Virtainer``

# Usage
``./config-creator.sh``<br/>
``./run.sh -vm <config>.conf``

# Quickly creating a (live) Linux config
``./quick-linux.sh <iso> <snapshot (on/off)>``

# Quickly setting up a Linux VM
``./quick-setup.sh``
