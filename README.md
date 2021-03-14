# Virtainer
QEMU script supporting Linux, Windows and macOS guests

# History
Originally, I've made **MyFastEmulator**, which was a fork of the **quickemu** project meant to expose more configuration options and be faster. However, the code **was a mess** and I finally **abandonned it**. Not long after, I decided to start another QEMU script named **Virtainer** which would be coded from scratch using **quickemu**'s and **MyFastEmulator**'s code.

# Features
- **Full support** for **Linux, Windows and macOS guests**
- **Made around** the **latest QEMU version**
- **Very fast** and **easy to use**
- **And more!**

# Files
run.sh : The classic script, run any type of VM. (Linux, Windows and macOS)
live-linux.sh : Create a Linux VM quickly for Live purposes only with a single command, both config and disk are deleted after shutdown.
quick-linux.sh : Create a Linux VM quickly with a single command, both config and disk are kept after shutdown.
config-creator.sh : Create a config of any type. (Linux, Windows and macOS)

# Download
``git clone https://github.com/NanoSoftwares/Virtainer.git``
``cd Virtainer``

# Usage
``./config-creator.sh``
``./run.sh -vm <config>.conf``

# Create a quick Live Linux config
``./live-linux.sh <iso>``

# Create a quick Linux config
``./quick-linux.sh <iso>``
