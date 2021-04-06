#!/bin/bash

function start()
{
	echo "Welcome to the Virtainer config creator!"

	echo "Name of the guest :"
	read name

	echo "Drag & drop the boot ISO :"
	read iso
	iso=$(echo $iso | cut -d "'" -f 2)

	echo "How much disk space should the guest have? (format : <number><G,M,K>, default : 40G)"
	read disk_size

	echo "How much RAM should the guest have? (format : <number><G,M,K>, default : 1G)"
	read ram

	echo "How many cores should the guest have? (default : 1)"
	read cores

	echo "How many threads should the guest have? (default : 1)"
	read threads

	echo "What should be the display UI for the guest? (options : gtk/sdl/spice-app, default : gtk)"
	read display

	echo "Should the guest have accelerated graphics? (options : on/off, default : on)"
	read accelerated_graphics

	echo "What should be the CPU model of the guest? (default : max)"
	read cpu

	echo "Should nested virtualization be enabled in the guest? (options : on/off, default : off)"
	read nested_virtualization

	echo "For what operating system should the guest be optimized for? (options : windows(7/10)/linux/macos/legacy, default : linux)"
	read optimize_system

	echo "What should be the type of BIOS of the guest? (options : efi/legacy, default : efi)"
	read bios

	echo "Would you like to not save anything to the virtual disk? (options : on/off, default : off)"
	read snapshot

	echo "Would you like to force adding the ISO images (main ISO + driver ISO, if any) even if the OS is installed? (options : on/off, default : off)"
	read force_add_iso_images

	echo "Would you like to passthrough any USB device? (syntax : ('vendorid:productid', 'vendorid2:productid2', ..), default : ())"
	read usb_devices

	file="${name}.conf"

	addOptionSafe ${file} "iso" ${iso}
	addOptionSafe ${file} "disk_size" ${disk_size}
	addOptionSafe ${file} "ram" ${ram}
	addOptionSafe ${file} "cores" ${cores}
	addOptionSafe ${file} "threads" ${threads}
	addOptionSafe ${file} "display" ${display}
	addOptionSafe ${file} "accelerated_graphics" ${accelerated_graphics}
	addOptionSafe ${file} "cpu" ${cpu}
	addOptionSafe ${file} "nested_virtualization" ${nested_virtualization}
	addOptionSafe ${file} "optimize_system" ${optimize_system}
	addOptionSafe ${file} "bios" ${bios}
	addOptionSafe ${file} "snapshot" ${snapshot}
	addOptionSafe ${file} "force_add_iso_images" ${force_add_iso_images}
	addOptionSafe ${file} "usb_devices" ${usb_devices}
}

function addOptionSafe()
{
	file="$1"
	option="$2"
	value="$3"

	if [ ! -z "${value}" -a "${value}" != " " ]; then
		echo "${option}=${value}" >> ${file}
	fi
}

start