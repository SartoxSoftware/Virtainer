#!/bin/bash
export LC_ALL=C

iso=""
vmName=""
vmFile=""
snapshot=""

function usage()
{
	echo "<script>.sh <iso> <snapshot (on/off)>"
	exit 0
}

function startVM()
{
	echo "iso=${iso}" >> ${vmFile}
	echo "ram=2G" >> ${vmFile}
	echo "cores=2" >> ${vmFile}
	echo "bios=legacy" >> ${vmFile}
	if [ ${snapshot} == "on" ]; then
		echo "snapshot=on" >> ${vmFile}
	fi
	echo "display=sdl" >> ${vmFile}

	bash run.sh -vm ${vmFile}
	if [ ${snapshot} == "on" ]; then
		rm VMs/${vmName}.qcow2
		rm ${vmFile}
	fi
}

if [ $# -lt 0 ]; then
	usage
else
	while [ $# -gt 0 ]; do
		case "${1}" in
			*)
				iso="${1}"
				vmName=$(basename "${iso}" .iso)
				vmFile="${vmName}.conf"
				snapshot="${2}"
				shift
				shift;;
		esac
	done
fi

startVM