#!/bin/bash
export LC_ALL=C

iso=""
vmName=""
vmFile=""

function usage()
{
	echo "<script>.sh <iso>"
	exit 0
}

function startVM()
{
	echo "iso=${iso}" >> ${vmFile}
	echo "ram=2G" >> ${vmFile}
	echo "cores=2" >> ${vmFile}
	echo "bios=legacy" >> ${vmFile}

	bash run.sh -vm ${vmFile}
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
				shift
				shift;;
		esac
	done
fi

startVM