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

	echo "For what operating system should the guest be optimized for? (options : windows/linux/macos, default : linux)"
	read optimize_system

	echo "What should be the type of BIOS of the guest? (options : efi/legacy, default : efi)"
	read bios

	echo "How much video memory in megabytes should the guest have? (default : 128)"
	read video_memory

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
	addOptionSafe ${file} "video_memory" ${video_memory}
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