#!/usr/bin/env bash
export LC_ALL=C

version="2.0.0"
launcher=""
name=""
disk=""
ovmfCode="/usr/share/OVMF/OVMF_CODE.fd"
ovmfVars="/usr/share/OVMF/OVMF_VARS.fd"
diskDir="$PWD/VMs"
winDir="$PWD/Windows"
macDir="$PWD/macOS"
openCoreVersion="16"
drives=""
machine="q35"
extra=""
audio="-audiodev pa,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0"
cpuTweaks=""
graphics="virtio-vga-gl"
peripherals="-device virtio-keyboard-pci -device virtio-tablet-pci"
usb="qemu-xhci,p2=8,p3=8"
network="virtio-net-pci"
diskInterface="-device virtio-blk-pci,drive=drive0,scsi=off"
cpuInfo=$(cat /proc/cpuinfo | grep Intel)

function usage()
{
	echo "Virtainer v${version} - All valid options"
	echo "<config>.conf          - Starts a VM with the choosed configuration file."
	exit 0
}

function loadDefaultConfig()
{
	if [ -z ${ram} ]; then
		ram="2G"
	fi

	if [ -z ${display} ]; then
		display="sdl"
	fi

	if [ -z ${cores} ]; then
		cores="2"
	fi

	if [ -z ${threads} ]; then
		threads="2"
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

	if [ -z ${firmware} ]; then
		firmware="efi"
	fi

	if [ -z ${nested_virtualization} ]; then
		nested_virtualization="off"
	fi

	if [ -z ${disk_size} ]; then
		disk_size="40G"
	fi

	if [ -z ${image_format} ]; then
		image_format="qcow2"
	fi

	if [ -z ${cache} ]; then
		cache="none,aio=native"
	fi

	if [ -z ${snapshot} ]; then
		snapshot="off"
	fi
}

function enableNestedVirtualization()
{
	if [[ $cpuInfo == *"Intel"* ]]; then
		nestedIntel=$(cat /sys/module/kvm_intel/parameters/nested)
		if [ ${nestedIntel} == "N" ] || [ ${nestedIntel} == "0" ]; then
			sudo modprobe -r kvm_intel
			sudo modprobe kvm_intel nested=1
		fi
		extra="${extra} -device intel-iommu"
	else
		nestedAmd=$(cat /sys/module/kvm_amd/parameters/nested)
		if [ ${nestedAmd} == "N" ] || [ ${nestedAmd} == "0" ]; then
			sudo modprobe -r kvm_amd
			sudo modprobe kvm_amd nested=1
		fi
		extra="${extra} -device amd-iommu"
	fi
}

function disableNestedVirtualization()
{
	if [[ $cpuInfo == *"Intel"* ]]; then
		nestedIntel=$(cat /sys/module/kvm_intel/parameters/nested)
		if [ ${nestedIntel} == "Y" ] || [ ${nestedIntel} == "1" ]; then
			sudo modprobe -r kvm_intel
			sudo modprobe kvm_intel nested=0
		fi
	else
		nestedAmd=$(cat /sys/module/kvm_amd/parameters/nested)
		if [ ${nestedAmd} == "Y" ] || [ ${nestedAmd} == "1" ]; then
			sudo modprobe -r kvm_amd
			sudo modprobe kvm_amd nested=0
		fi
	fi
}

function setupDisk()
{
	if [ ${optimize_system} != "macos" ]; then
		drives="${drives} -drive media=cdrom,index=0,file=${iso}"
	fi
}

function start()
{
	echo "Virtainer v${version} - Starting VM..."

	# Check if VM configuration file exists
	if [ ! -e "${name}.conf" ]; then
		echo "The selected configuration file does not exist!"
		exit 0
	fi

	# Create VMs directory if it doesn't exist
	if [ ! -e ${diskDir} ]; then
		mkdir ${diskDir}
	fi

	# Use virtio-vga without VirGL if accelerated graphics are explicitly disabled
	if [ ${accelerated_graphics} == "off" ]; then
		graphics="virtio-vga"
	fi

	# Optimize settings for certain operating systems
	if [ ${optimize_system} == "linux" ]; then
		extra="-device virtio-rng-pci,rng=rng0 -object rng-random,id=rng0,filename=/dev/urandom"
	elif [ ${optimize_system} == "windows" ]; then
		# Create Windows directory if it doesn't exist
		if [ ! -e ${winDir} ]; then
			mkdir ${winDir}
		fi

		# Download VirtIO guest tools ISO if it doesn't exist
		if [ ! -f "${winDir}/virtio-win.iso" ]; then
			wget "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso" -O "${winDir}/virtio-win.iso"
		fi

		drives="-drive media=cdrom,index=1,file=${winDir}/virtio-win.iso"
		cpuTweaks=",hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time"
		extra="-no-hpet"
	elif [ ${optimize_system} == "macos" ]; then
		# SMEP freezes the macOS installer! (Seen on Monterey)
		cpuTweaks=",vendor=GenuineIntel,+kvm_pv_unhalt,+kvm_pv_eoi,+hypervisor,+invtsc,+movbe,+pcid,+sse3,+ssse3,+sse4.2,+popcnt,+aes,+avx2,+avx,+fma,+bmi1,+bmi2,+xsave,+xsavec,+xsaveopt,+xgetbv1,check"

		if [[ $cpuInfo == *"AMD"* ]]; then
			cpuTweaks="${cpuTweaks},+fma4"
		fi

		# pwetty pwease dowont steal owour wowork
		extra="-device isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
		drives="-drive id=drive1,if=none,cache=${cache},format=raw,file=$PWD/macOS/OpenCore.iso -device virtio-blk-pci,drive=drive1,scsi=off -drive id=drive2,if=none,cache=${cache},format=dmg,file=${macDir}/BaseSystem.dmg -device virtio-blk-pci,drive=drive2,scsi=off"
		
		if [ ! -e ${macDir} ]; then
			mkdir ${macDir}
		fi

		if [ ! -f "${macDir}/OpenCore.iso" ]; then
			wget "https://github.com/thenickdude/KVM-Opencore/releases/download/v${openCoreVersion}/OpenCore-v${openCoreVersion}.iso.gz" -O "${macDir}/OpenCore.iso.gz"
			gzip -d -f "${macDir}/OpenCore.iso.gz"
		fi

		if [ ! -f "${macDir}/BaseSystem.dmg" ]; then
			if [ ! -f "${macDir}/fetch.py" ]; then
				wget "https://raw.githubusercontent.com/kholia/OSX-KVM/master/fetch-macOS-v2.py" -O "${macDir}/fetch.py"

				pip3 install requests
				pip3 install click
			fi

			python3 "${macDir}/fetch.py" --action download -o ${macDir} -os latest
		fi
	fi

	# Enable nested virtualization if requested
	if [ ${nested_virtualization} == "on" ]; then
		enableNestedVirtualization
	else
		disableNestedVirtualization
	fi

	# Add snapshot support if requested
	if [ ${snapshot} == "on" ]; then
		extra="${extra} -snapshot"
	fi

	# Use EFI if requested
	if [ ${firmware} == "efi" ]; then
		extra="${extra} -drive if=pflash,format=raw,readonly=on,file=${ovmfCode} -drive if=pflash,format=raw,readonly=on,file=${ovmfVars}"
	fi

	# Setup virtual disk
	if [ ! -f ${disk} ]; then
		qemu-img create -q -f ${image_format} ${disk} ${disk_size}		
		setupDisk
	else
		diskSize=$(stat -c%s ${disk})
		if [ ${diskSize} -le $((197632 * 8)) ]; then
			setupDisk
		fi
	fi

	# Launch QEMU
	qemu-system-x86_64 \
		-name ${name},process=${name}  \
		-enable-kvm -machine ${machine},nvdimm=on -smbios type=2 \
		-parallel none -serial none \
		-cpu ${cpu},kvm=on${cpuTweaks} -smp sockets=1,dies=1,cores=${cores},threads=${threads} \
		-m ${ram} -device virtio-balloon-pci \
		-device ${graphics} -display ${display},gl=${accelerated_graphics} \
		-device ${usb},id=usb ${peripherals} \
		-netdev user,hostname=${name},id=nic -device ${network},netdev=nic \
      	-rtc base=localtime,clock=host \
      	-device virtio-serial-pci \
      	-chardev spicevmc,id=spicechannel0,name=vdagent \
      	-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
      	-chardev socket,path=/tmp/qga.sock,server=on,wait=off,id=spicechannel1 \
    	-device virtserialport,chardev=spicechannel1,name=org.qemu.guest_agent.0 \
		-drive if=none,id=drive0,discard=unmap,cache=${cache},format=${image_format},file=${disk} \
		${extra} ${audio} ${drives} ${diskInterface} \
		"${@}"
}

if [ $# -lt 1 ]; then
	usage
else
	while [ $# -gt 0 ]; do
		case "${1}" in
			*)
				# Load default config
				source "${2}"
				loadDefaultConfig

				# Populate some options
				launcher=$(basename "${0}")
				name=$(basename "${2}" .conf)
				disk="${diskDir}/${name}.${image_format}"

				shift
				shift;;
		esac
	done
fi

start