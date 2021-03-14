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

cpuInfo=$(cat /proc/cpuinfo | grep Intel)

function startVM()
{
	echo "QEMU v${qemuVer} - QEMU Script v${qemuScriptVer} - Adapted for QEMU v5.2.0"
	echo ""

	source "${vmFile}"
	
	if [ ! -e "$PWD/VMs" ]; then
		mkdir "$PWD/VMs"
	fi
	vmDisk="$PWD/VMs/${vmName}.qcow2"

	if [ ${XDG_SESSION_TYPE} == "x11" ]; then
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

	if [ ${optimize_system} == "linux" ]; then
		vmSystemGraphics="virtio-vga,virgl=${accelerated_graphics}"
		vmSystemExtra="-device virtio-rng-pci,rng=rng0 -object rng-random,id=rng0,filename=/dev/urandom"
	elif [ ${optimize_system} == "windows" ]; then
		vmSystemGraphics="qxl-vga,vgamem_mb=256"
		vmSystemExtra="-no-hpet -chardev spiceport,name=org.spice-space.stream.0,id=spicechannel2 -device virtserialport,bus=virtio-serial-bus.0,nr=21,chardev=spicechannel2,name=org.spice-space.stream.0 -chardev spiceport,name=org.spice-space.webdav.0,id=spicechannel3 -device virtserialport,bus=virtio-serial-bus.0,nr=24,chardev=spicechannel3,name=org.spice-space.webdav.0"
		vmCpuTweaks=",hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time"
		vmUsb="usb-ehci"

		display="spice-app"
	elif [ ${optimize_system} == "macos" ]; then
		vmCpuTweaks=",vendor=GenuineIntel,+kvm_pv_unhalt,+kvm_pv_eoi,+hypervisor,+invtsc"

		if [[ $cpuInfo == *"AMD"* ]]; then
			cpu="Penryn"
			vmCpuTweaks="${vmCpuTweaks},+pcid,+ssse3,+sse4.2,+popcnt,+aes,+avx2,+avx,+fma,+fma4,+bmi1,+bmi2,+xsave,+xsaveopt,check"
		fi

		vmSystemExtra="-device isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc -drive id=drive1,if=none,cache=directsync,aio=native,format=qcow2,file=$PWD/macOS/OpenCore.qcow2 -device virtio-blk-pci,drive=drive1,scsi=off"
		vmSystemGraphics="VGA,vgamem_mb=256"
		vmUsb="usb-ehci"
		vmNetwork="vmxnet3,mac=52:54:00:c9:18:27"

		if [ ! -e "$PWD/macOS" ]; then
			mkdir "$PWD/macOS"
		fi

		if [ ! -f "$PWD/macOS/OpenCore.qcow2" ]; then
			wget "https://github.com/thenickdude/KVM-Opencore/releases/download/v10/OpenCore-v10.iso.gz" -O "$PWD/macOS/OpenCore.iso.gz"
			gzip -d -f "$PWD/macOS/OpenCore.iso.gz"
			
			${qemuImg} convert "$PWD/macOS/OpenCore.iso" -O qcow2 "$PWD/macOS/OpenCore.qcow2"
			rm "$PWD/macOS/OpenCore.iso"

			echo ""
		fi

		if [ ! -f "$PWD/macOS/BaseSystem.qcow2" ]; then
			if [ ! -f "$PWD/macOS/fetch.py" ]; then
				wget "https://github.com/foxlet/macOS-Simple-KVM/raw/master/tools/FetchMacOS/fetch-macos.py" -O "$PWD/macOS/fetch.py"

				${pip} install requests
				${pip} install click
			fi

			${python} "$PWD/macOS/fetch.py" -o "$PWD/macOS/BaseSystem/"
			${qemuImg} convert "$PWD/macOS/BaseSystem/BaseSystem.dmg" -O qcow2 "$PWD/macOS/BaseSystem.qcow2"

			rm -r -f "$PWD/macOS/BaseSystem"
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
		vmSystemExtra="${vmSystemExtra} -drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/x64/OVMF_CODE.fd -drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/x64/OVMF_VARS.fd"
	fi

	if [ ! -f "${vmDisk}" ]; then
		${qemuImg} create -q -f qcow2 "${vmDisk}" ${disk_size}
		
		if [ ${optimize_system} != "macos" ]; then
			vmSystemDrives="-drive media=cdrom,index=0,file=${iso}"
		else
			vmSystemExtra="${vmSystemExtra} -drive id=drive2,if=none,cache=directsync,aio=native,format=qcow2,file=$PWD/macOS/BaseSystem.qcow2 -device virtio-blk-pci,drive=drive2,scsi=off"
		fi

		if [ ${optimize_system} == "windows" ]; then
			if [ ! -e "$PWD/Windows" ]; then
				mkdir "$PWD/Windows"
			fi

			if [ ! -f "$PWD/Windows/virtio-win.iso" ]; then
				wget "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso" -O "$PWD/Windows/virtio-win.iso"
				echo ""
			fi

			vmSystemDrives="${vmSystemDrives} -drive media=cdrom,index=1,file=$PWD/Windows/virtio-win.iso"
		fi
	else
		diskSize=$(stat -c%s "${vmDisk}")
		if [ ${diskSize} -le 1581056 ]; then
			if [ ${optimize_system} != "macos" ]; then
				vmSystemDrives="-drive media=cdrom,index=0,file=${iso}"
			else
				vmSystemExtra="${vmSystemExtra} -drive id=drive2,if=none,cache=directsync,aio=native,format=qcow2,file=$PWD/macOS/BaseSystem.qcow2 -device virtio-blk-pci,drive=drive2,scsi=off"
			fi

			if [ ${optimize_system} == "windows" ]; then
				if [ ! -e "$PWD/Windows" ]; then
					mkdir "$PWD/Windows"
				fi

				if [ ! -f "$PWD/Windows/virtio-win.iso" ]; then
					wget "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso" -O "$PWD/Windows/virtio-win.iso"
					echo ""
				fi

				vmSystemDrives="${vmSystemDrives} -drive media=cdrom,index=1,file=$PWD/Windows/virtio-win.iso"
			fi
		fi
	fi

	echo "RAM                   : ${ram}"
	echo "Cores                 : ${cores}"
	echo "CPU                   : ${cpu^}"
	echo "Accelerated Graphics  : ${accelerated_graphics^^}"
	echo "Resolution            : ${vmWidth}x${vmHeight}"
	echo "System optimization   : ${optimize_system^}"
	echo "Display               : ${display}"
	echo "BIOS                  : ${bios^}"
	echo "Nested virtualization : ${nested_virtualization^^}"
	echo ""
	echo "Starting..."
	echo ""

	${qemu} \
		-name ${vmFile},process=${vmFile}  \
		-enable-kvm -machine q35,vmport=off,nvdimm=on \
		-smbios type=2 \
		-cpu ${cpu},kvm=on${vmCpuTweaks} -smp sockets=1,cores=${cores},threads=${threads} \
		-m ${ram} -device virtio-balloon-pci \
		-device ${vmSystemGraphics},xres=${vmWidth},yres=${vmHeight} \
		-display ${display},gl=${accelerated_graphics} \
		-device ${vmUsb},id=usb -device usb-kbd,bus=usb.0 -device usb-tablet,bus=usb.0 \
		-netdev user,hostname="${vmName}",id=nic -device ${vmNetwork},netdev=nic \
		-audiodev pa,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0 \
      	-rtc base=localtime,clock=host \
      	-device virtio-serial-pci \
      	-chardev spicevmc,id=spicechannel0,name=vdagent \
      	-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
      	-chardev socket,path=/tmp/qga.sock,server,nowait,id=spicechannel1 \
    	-device virtserialport,chardev=spicechannel1,name=org.qemu.guest_agent.0 \
    	${vmSystemExtra} ${vmSystemDrives} \
		-drive if=none,id=drive0,cache=directsync,aio=native,format=qcow2,file="${vmDisk}" \
		-device virtio-blk-pci,drive=drive0,scsi=off \
		"${@}"
}

function usage()
{
	echo "Virtainer ${qemuScriptVer} - All valid options"
	echo "-vm <config>.conf          - Starts a VM with the choosed configuration file."
	echo "-create-shortcut           - Creates a desktop shortcut for the current VM."
	echo "-delete-shortcut           - Deletes the desktop shortcut of the current VM."
	exit 0
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