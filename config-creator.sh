#!/bin/bash

function start()
{
	echo "Name:"
	read name

	echo "Boot image:"
	read boot_image

	echo "Disk space: (<number><GMK>, default: 40G)"
	read disk_size

	echo "RAM: (<number><GMK>, default: 1G)"
	read ram

	echo "Cores: (default: 2)"
	read cores

	echo "Threads: (default: 2)"
	read threads

	echo "QEMU display: (gtk/sdl/spice-app, default: sdl)"
	read display

	echo "Accelerated graphics: (on/off, default: on)"
	read accelerated_graphics

	echo "CPU model: (default: max)"
	read cpu

	echo "Nested virtualization: (on/off, default: off)"
	read nested_virtualization

	echo "OS optimization: (linux/windows/macos, default: linux)"
	read optimize_system

	echo "Firmware: (efi/legacy, default: efi)"
	read firmware

	echo "Secure Boot: (on/off, default: off)"
	read secure_boot

	echo "Snapshot: (on/off, default: off)"
	read snapshot

	echo "Disk cache: (none/unsafe/writethrough/directsync/writeback, default: none)"
	read cache

	echo "Disk format: (qcow2/raw/vhd/vdi/vmdk, default: qcow2)"
	read disk_format

	file="${name}.conf"

	addOptionSafe ${file} "boot_image" ${boot_image}
	addOptionSafe ${file} "disk_size" ${disk_size}
	addOptionSafe ${file} "ram" ${ram}
	addOptionSafe ${file} "cores" ${cores}
	addOptionSafe ${file} "threads" ${threads}
	addOptionSafe ${file} "display" ${display}
	addOptionSafe ${file} "accelerated_graphics" ${accelerated_graphics}
	addOptionSafe ${file} "cpu" ${cpu}
	addOptionSafe ${file} "nested_virtualization" ${nested_virtualization}
	addOptionSafe ${file} "optimize_system" ${optimize_system}
	addOptionSafe ${file} "firmware" ${firmware}
	addOptionSafe ${file} "secure_boot" ${secure_boot}
	addOptionSafe ${file} "snapshot" ${snapshot}
	addOptionSafe ${file} "cache" ${cache}
	addOptionSafe ${file} "disk_format" ${disk_format}
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