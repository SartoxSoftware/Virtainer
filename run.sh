#!/bin/bash
export LC_ALL=C

qemu=$(which qemu-system-x86_64)
qemuImg=$(which qemu-img)
qemuVer=$(${qemu} -version | head -n1 | cut -d' ' -f4 | cut -d'(' -f1)
qemuScriptVer="0.1"

pip=$(which pip3)
python=$(which python3)

launcher=""

vmFile=""
vmName=""
vmDisk=""

vmWidth=800
vmHeight=600

vmSystemGraphics=""
vmSystemExtra=""
vmDriverIso=""
vmSystemDrives=""
vmUsb="qemu-xhci,p2=8,p3=8"
vmNetwork="virtio-net-pci"
vmCpuTweaks=""
vmDiskDrive="-device virtio-blk-pci,drive=drive0,scsi=off"
vmMachine="q35"
vmAudio="-audiodev pa,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0"
vmPeripherals="-device usb-kbd,bus=usb.0 -device usb-tablet,bus=usb.0"

cpuInfo=$(cat /proc/cpuinfo | grep Intel)

usbPassthrough=""
usbDevices=""

function enableUSBPassthrough()
{
	device=""
	usbBus=""
	usbDev=""
	usbName=""
	vendorId=""
	productId=""
	tempScript=$(mktemp)
	execScript=0

	if (( ${#usb_devices[@]} )); then
		echo "#!/bin/bash" > "${tempScript}"

		for device in "${usb_devices[@]}"; do
			vendorId=$(echo ${device} | cut -d':' -f1)
			productId=$(echo ${device} | cut -d':' -f2)

			usbBus=$(lsusb -d ${vendorId}:${productId} | cut -d' ' -f2)
			usbDev=$(lsusb -d ${vendorId}:${productId} | cut -d' ' -f4 | cut -d':' -f1)
			usbName=$(lsusb -d ${vendorId}:${productId} | cut -d' ' -f7-)

			usbDevices="${usbDevices} ${usbName}"
			usbPassthrough="${usbPassthrough} -device usb-host,vendorid=0x${vendorId},productid=0x${productId},bus=usb.0"

			if [ ! -w /dev/bus/usb/${usbBus}/${usbDev} ]; then
        		execScript=1
        		echo "chown root:${USER} /dev/bus/usb/${usbBus}/${usbDev}" >> "${tempScript}"
      		fi

      		if [ ${execScript} -eq 1 ]; then
      			chmod +x "${tempScript}"
			    sudo "${tempScript}"
			    
			    if [ $? -ne 0 ]; then
			    	usbDevices="Requested USB devices are not accessible."
			    fi
		    fi

    		rm -f "${tempScript}"
		done
	else
		usbDevices="None"
	fi
}

function startVM()
{
	echo "QEMU v${qemuVer} - QEMU Script v${qemuScriptVer} - Adapted for QEMU v6.0.0"
	echo ""

	source "${vmFile}"
	
	if [ ! -e "$PWD/VMs" ]; then
		mkdir "$PWD/VMs"
	fi
	vmDisk="$PWD/VMs/${vmName}.qcow2"

	if [ "${XDG_SESSION_TYPE}" == "x11" ]; then
		vmWidth=$(xrandr --listmonitors | grep -v Monitors | cut -d' ' -f4 | cut -d'/' -f1 | sort | head -n1)
		vmHeight=$(xrandr --listmonitors | grep -v Monitors | cut -d' ' -f4 | cut -d'/' -f2 | cut -d'x' -f2 | sort | head -n1)
	fi

	if [ -z ${ram} ]; then
		ram="1G"
	fi

	if [ -z ${display} ]; then
		display="gtk"
	fi

	if [ -z ${cores} ]; then
		cores="1"
	fi

	if [ -z ${threads} ]; then
		threads="1"
	fi

	if [ -z ${cpu} ]; then
		cpu="max"
	fi

	if [ -z ${accelerated_graphics} ]; then
		accelerated_graphics="on"
	fi

	if [ -z ${optimize_system} ]; then
		optimize_system="linux"
	fi

	if [ -z ${bios} ]; then
		bios="efi"
	fi

	if [ -z ${nested_virtualization} ]; then
		nested_virtualization="off"
	fi

	if [ -z ${disk_size} ]; then
		disk_size="40G"
	fi

	if [ -z ${snapshot} ]; then
		snapshot="off"
	fi

	if [ -z ${force_add_iso_images} ]; then
		force_add_iso_images="off"
	fi

	if [ -z ${usb_devices} ]; then
		usb_devices=()
	fi

	if [ ${optimize_system} == "linux" ]; then
		vmSystemGraphics="virtio-vga,virgl=${accelerated_graphics},xres=${vmWidth},yres=${vmHeight}"
		vmSystemExtra="-device virtio-rng-pci,rng=rng0 -object rng-random,id=rng0,filename=/dev/urandom"
	elif [ ${optimize_system} == "windows10" ]; then
		vmSystemGraphics="qxl-vga,vgamem_mb=256"
		vmCpuTweaks=",hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time"
		vmSystemExtra="-no-hpet -chardev spiceport,name=org.spice-space.stream.0,id=spicechannel2 -device virtserialport,bus=virtio-serial-bus.0,nr=21,chardev=spicechannel2,name=org.spice-space.stream.0 -chardev spiceport,name=org.spice-space.webdav.0,id=spicechannel3 -device virtserialport,bus=virtio-serial-bus.0,nr=24,chardev=spicechannel3,name=org.spice-space.webdav.0"
			
		display="spice-app"
	elif [ ${optimize_system} == "windows7" ]; then
		vmSystemGraphics="qxl-vga,vgamem_mb=256,xres=${vmWidth},yres=${vmHeight}"
		vmSystemExtra="-no-hpet -chardev spiceport,name=org.spice-space.stream.0,id=spicechannel2 -device virtserialport,bus=virtio-serial-bus.0,nr=21,chardev=spicechannel2,name=org.spice-space.stream.0 -chardev spiceport,name=org.spice-space.webdav.0,id=spicechannel3 -device virtserialport,bus=virtio-serial-bus.0,nr=24,chardev=spicechannel3,name=org.spice-space.webdav.0"
		vmCpuTweaks=",hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time"
		vmUsb="usb-ehci"
		vmDiskDrive="-device ahci,id=ahci -device ide-hd,drive=drive0,bus=ahci.0"

		display="spice-app"
	elif [ ${optimize_system} == "legacy" ]; then
		vmSystemGraphics="cirrus-vga,vgamem_mb=16"
		vmSystemExtra="-no-hpet"

		vmUsb="piix4-usb-uhci"
		vmPeripherals=""
		
		vmDiskDrive="-device ide-hd,drive=drive0"

		vmMachine="pc"
		vmNetwork="pcnet"

		vmAudio="-device AC97"
		bios="legacy"
	elif [ ${optimize_system} == "macos" ]; then
		vmCpuTweaks=",vendor=GenuineIntel,+kvm_pv_unhalt,+kvm_pv_eoi,+hypervisor,+invtsc"

		if [[ $cpuInfo == *"AMD"* ]]; then
			cpu="Penryn"
			vmCpuTweaks="${vmCpuTweaks},+pcid,+ssse3,+sse4.2,+popcnt,+aes,+avx2,+avx,+fma,+fma4,+bmi1,+bmi2,+xsave,+xsaveopt,check"
		fi

		vmSystemExtra="-device isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc -drive id=drive1,if=none,cache=directsync,aio=native,format=raw,file=$PWD/macOS/OpenCore.iso -device virtio-blk-pci,drive=drive1,scsi=off"
		vmSystemGraphics="VGA,vgamem_mb=256,xres=${vmWidth},yres=${vmHeight}"
		vmUsb="usb-ehci"
		vmNetwork="vmxnet3,mac=52:54:00:c9:18:27"

		if [ ! -e "$PWD/macOS" ]; then
			mkdir "$PWD/macOS"
		fi

		if [ ! -f "$PWD/macOS/OpenCore.iso" ]; then
			wget "https://github.com/thenickdude/KVM-Opencore/releases/download/v10/OpenCore-v10.iso.gz" -O "$PWD/macOS/OpenCore.iso.gz"
			gzip -d -f "$PWD/macOS/OpenCore.iso.gz"

			echo ""
		fi

		if [ ! -f "$PWD/macOS/BaseSystem/BaseSystem.dmg" ]; then
			if [ ! -f "$PWD/macOS/fetch.py" ]; then
				wget "https://github.com/foxlet/macOS-Simple-KVM/raw/master/tools/FetchMacOS/fetch-macos.py" -O "$PWD/macOS/fetch.py"

				${pip} install requests
				${pip} install click
			fi

			${python} "$PWD/macOS/fetch.py" -o "$PWD/macOS/BaseSystem/"
			echo ""
		fi
	fi

	if [ ${snapshot} == "on" ]; then
		vmSystemExtra="${vmSystemExtra} -snapshot"
	fi

	if [ ${nested_virtualization} == "on" ]; then
		echo "WARNING : Enabling nested virtualization might result in degraded performance in the guest machine."
		echo ""

		enableNestedVirtualization
	fi

	if [ ${bios} == "efi" ]; then
		vmSystemExtra="${vmSystemExtra} -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/x64/OVMF_CODE.fd -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/x64/OVMF_VARS.fd"
	fi

	if [ ! -f "${vmDisk}" ]; then
		${qemuImg} create -q -f qcow2 "${vmDisk}" ${disk_size}		
		setupDisk
	else
		diskSize=$(stat -c%s "${vmDisk}")
		if [ ${diskSize} -le $((197632 * 8)) ] || [ ${force_add_iso_images} == "on" ]; then
			setupDisk
		fi
	fi

	enableUSBPassthrough

	echo "RAM                   : ${ram}"
	echo "Cores                 : ${cores}"
	echo "CPU                   : ${cpu^}"
	echo "Accelerated Graphics  : ${accelerated_graphics^^}"
	echo "Resolution            : ${vmWidth}x${vmHeight}"
	echo "System optimization   : ${optimize_system^}"
	echo "Display               : ${display}"
	echo "BIOS                  : ${bios^}"
	echo "Nested virtualization : ${nested_virtualization^^}"
	echo "USB passthrough       : ${usbDevices}"
	echo ""
	echo "Starting..."
	echo ""

	${qemu} \
		-name "${vmFile}",process="${vmFile}"  \
		-enable-kvm -machine ${vmMachine},vmport=off,nvdimm=on \
		-smbios type=2 \
		-cpu ${cpu},kvm=on${vmCpuTweaks} -smp sockets=1,cores=${cores},threads=${threads} \
		-m ${ram} -device virtio-balloon-pci \
		-device ${vmSystemGraphics} \
		-display ${display},gl=${accelerated_graphics} \
		-device ${vmUsb},id=usb ${vmPeripherals} ${usbPassthrough} \
		-netdev user,hostname="${vmName}",id=nic -device ${vmNetwork},netdev=nic \
		${vmAudio} \
      	-rtc base=localtime,clock=host \
      	-device virtio-serial-pci \
      	-chardev spicevmc,id=spicechannel0,name=vdagent \
      	-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
      	-chardev socket,path=/tmp/qga.sock,server=on,wait=off,id=spicechannel1 \
    	-device virtserialport,chardev=spicechannel1,name=org.qemu.guest_agent.0 \
    	${vmSystemExtra} ${vmSystemDrives} \
		-drive if=none,id=drive0,cache=directsync,aio=native,format=qcow2,file="${vmDisk}" \
		${vmDiskDrive} \
		"${@}"
}

function setupDisk()
{
	if [ ${optimize_system} == "macos" ]; then
		vmSystemExtra="${vmSystemExtra} -drive id=drive2,if=none,cache=directsync,aio=native,format=dmg,file=$PWD/macOS/BaseSystem/BaseSystem.dmg -device virtio-blk-pci,drive=drive2,scsi=off"
	else
		vmSystemDrives="-drive media=cdrom,index=0,file=${iso}"
	fi

	if [ ${optimize_system} == "windows7" ] || [ ${optimize_system} == "windows10" ]; then
		if [ ! -e "$PWD/Windows" ]; then
			mkdir "$PWD/Windows"
		fi

		if [ ! -f "$PWD/Windows/virtio-win.iso" ]; then
			downloadGuestTools
		fi

		vmSystemDrives="${vmSystemDrives} -drive media=cdrom,index=1,file=$PWD/Windows/virtio-win.iso"
	fi
}

function usage()
{
	echo "Virtainer ${qemuScriptVer} - All valid options"
	echo "-vm <config>.conf          - Starts a VM with the choosed configuration file."
	echo "-create-shortcut           - Creates a desktop shortcut for the current VM."
	echo "-delete-shortcut           - Deletes the desktop shortcut of the current VM."
	exit 0
}

function downloadGuestTools()
{
	if [ ${optimize_system} == "windows10" ]; then
		wget "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso" -O "$PWD/Windows/virtio-win.iso"
	elif [ ${optimize_system} == "windows7" ]; then
		mkdir "$PWD/Windows/tools"
		wget "https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe" -O "$PWD/Windows/tools/guest_tools.exe"
		mkisofs -o "$PWD/Windows/virtio-win.iso" "$PWD/Windows/tools"
		rm -r -f "$PWD/Windows/tools"
	fi

	echo ""
}

function enableNestedVirtualization()
{
	if [ ${optimize_system} == "windows" ]; then
		vmCpuTweaks=",hypervisor=off"
	fi

	if [[ $cpuInfo == *"Intel"* ]]; then
		nestedIntel=$(cat /sys/module/kvm_intel/parameters/nested)
		if [ ${nestedIntel} == "N" ] || [ ${nestedIntel} == "0" ]; then
			echo "Sudo privileges are required to enable nested virtualization."
			echo ""
			
			sudo modprobe -r kvm_intel
			sudo modprobe kvm_intel nested=1
		fi
	else
		nestedAmd=$(cat /sys/module/kvm_amd/parameters/nested)
		if [ ${nestedAmd} == "N" ] || [ ${nestedAmd} == "0" ]; then
			echo "Sudo privileges are required to enable nested virtualization."
			echo ""

			sudo modprobe -r kvm_amd
			sudo modprobe kvm_amd nested=1
		fi
	fi
}

function createShortcut()
{
	shortcut="/home/${USER}/.local/share/applications/${vmName}.desktop"

	if [ ! -f ${shortcut} ]; then
		cat << EOF > ${shortcut}
[Desktop Entry]
Name=${vmName}
Comment=Launch ${vmName^} VM
Exec=${PWD}/${launcher} -vm ${PWD}/${vmFile}
Terminal=true
Type=Application
Version=${qemuScriptVer}
EOF

		chmod +x ${shortcut}
		echo "Successfully created a desktop shortcut for the current VM!"
	else
		echo "The desktop shortcut of the current VM already exists."
	fi
}

function deleteShortcut()
{
	shortcut="/home/${USER}/.local/share/applications/${vmName}.desktop"

	if [ -f ${shortcut} ]; then
		rm ${shortcut}
		echo "Successfully deleted the desktop shortcut of the current VM!"
	else
		echo "The desktop shortcut of the current VM doesn't exist."
	fi
}

if [ $# -lt 1 ]; then
	usage
else
	while [ $# -gt 0 ]; do
		case "${1}" in
			-vm)
				launcher=$(basename ${0})
				vmFile="${2}"
				vmName=$(basename "${vmFile}" .conf)
				shift
				shift;;
			-create-shortcut)
				createShortcut
				shift;;
			-delete-shortcut)
				deleteShortcut
				shift;;
			*)
				usage;;
		esac
	done
fi

startVM