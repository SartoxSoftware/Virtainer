#!/bin/bash

url=""
path=""
cores=""
file=""

function start()
{
	echo "Welcome to Virtainer's easy VM setup script!"
	echo "You'll have to choose the OS you want to install and a few simple options to be all set."
	echo ""
	echo "We'll first start by choosing the OS. Choose from the below list the one you want to install, then type its number and press enter."
	echo "Note that this lists only selects the 10 most popular Linux distributions out there. They aren't classified in any particular order whatsoever."
	echo "1. Ubuntu 20.04.2"
	echo "2. Ubuntu 21.04"
	echo "3. Fedora 34 Workstation"
	echo "4. Linux Mint 20.1"
	echo "5. Pop! OS 20.04"
	echo "6. Pop! OS 20.10"
	echo "7. elementary OS 5.1.7"
	echo "8. MX Linux 19.4"
	echo "9. Manjaro 21.0.3"
	echo "10. Debian 10.9"

	read choice

	if [ ${choice} == "1" ]; then
		url="https://releases.ubuntu.com/20.04.2.0/ubuntu-20.04.2.0-desktop-amd64.iso"
	elif [ ${choice} == "2" ]; then
		url="https://releases.ubuntu.com/21.04/ubuntu-21.04-desktop-amd64.iso"
	elif [ ${choice} == "3" ]; then
		url="https://download.fedoraproject.org/pub/fedora/linux/releases/34/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-34-1.2.iso"
	elif [ ${choice} == "4" ]; then
		url="https://mirrors.layeronline.com/linuxmint/stable/20.1/linuxmint-20.1-cinnamon-64bit.iso"
	elif [ ${choice} == "5" ]; then
		url="https://pop-iso.sfo2.cdn.digitaloceanspaces.com/20.04/amd64/intel/26/pop-os_20.04_amd64_intel_26.iso"
	elif [ ${choice} == "6" ]; then
		url="https://pop-iso.sfo2.cdn.digitaloceanspaces.com/20.10/amd64/intel/14/pop-os_20.10_amd64_intel_14.iso"
	elif [ ${choice} == "7" ]; then
		url="https://fra1.dl.elementary.io/download/MTYxOTkwNjY4OQ==/elementaryos-5.1-stable.20200814.iso"
	elif [ ${choice} == "8" ]; then
		url="https://downloads.sourceforge.net/project/mx-linux/Final/MX-19.4_x64.iso?ts=gAAAAABgjdDFnKbCrs8fMK6MQKZFozICBXkK2rZfqJkT8OYMscc3T6nEQTBjygFn-N2LHF5WD7CDC-xxg6quCpo9lLRX2Dy6Cw%3D%3D&r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fmx-linux%2Ffiles%2FFinal%2FMX-19.4_x64.iso%2Fdownload"
	elif [ ${choice} == "9" ]; then
		url="https://download.manjaro.org/xfce/21.0.3/manjaro-xfce-21.0.3-210428-linux510.iso"
	elif [ ${choice} == "10" ]; then
		url="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.9.0-amd64-xfce-CD-1.iso"
	fi

	echo "Downloading the choosed distribution..."
	path="$PWD/Distribution/distro-${choice}.iso"
	
	mkdir "$PWD/Distribution"
	wget "${url}" -O "${path}"

	echo "We'll now ask you a few questions regarding the VM. Most options will be configurated to have the best host-VM balance in terms of performance and stability, so no need to worry about that."
	
	echo "First, how much RAM will you allocate to your VM? We recommend at least 3 GB for a smooth usage. (<amount>[G,M], default : 1G)"
	read ram
	
	echo "Secondly, how much disk size will you allocate to your VM? The default should be enough for normal usage. (<amount>[G,M], default : 40G)"
	read disk_size

	echo "Thirdly, would you like to enable nested virtualization in your VM? There shouldn't be any reason to enable this unless you're a developer or a guy that likes to experiment :D (on/off, default : off)"
	read nested_virtualization

	echo "And finally, would you like to passthrough any USB devices to your VM? There shouldn't be any reason to passthrough any unless you're a gamer or, again, a guy that likes to experiment :D (syntax : ('vendorid:productid', 'vendorid2:productid2', ..), default : nothing)"
	read usb_devices

	echo "Creating configuration file..."
	
	file=$(basename "${path}" .iso)
	file="${file}.conf"

	cores=$(nproc)
	if [ ${cores} != 2 ]; then
		cores=$((cores / 2))
	fi

	addOptionSafe "${file}" "iso" "${path}"
	addOptionSafe "${file}" "disk_size" ${disk_size}
	addOptionSafe "${file}" "ram" ${ram}
	addOptionSafe "${file}" "cores" ${cores}
	addOptionSafe "${file}" "threads" $((cores / 2))
	addOptionSafe "${file}" "nested_virtualization" ${nested_virtualization}
	addOptionSafe "${file}" "usb_devices" ${usb_devices}

	echo "Would you like to start your newly created VM now? (yes/no, default : yes)"
	read startVM

	if [ "${startVM}" != "no" ]; then
		./run.sh -vm "${file}"
	fi
}

function addOptionSafe()
{
	file="$1"
	option="$2"
	value="$3"

	if [ ! -z "${value}" -a "${value}" != " " ]; then
		echo "${option}=${value}" >> "${file}"
	fi
}

start