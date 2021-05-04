#!/bin/sh
# Script to generate a "lightweigth" version of Vivado Lab

EXPVER="2020.2"

# Die with an error message
die() {
    echo "$*" >&2
    exit 1
}

# Show usage information
usage()
{
    NAME=`basename $0`
    cat <<EOT
$NAME [-h] <vivado_path>

  Generate a Vivado Lab docker image file for VCU118

    vivado_path:  Path to an existing Vivado Lab ${EXPVER} installation

    -h            Print this help message
EOT
}

abspath() {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

if [ $# -ne 1 ]; then
    die "Missing Vivado Lab path"
fi

if [ "$1" = "-h" ]; then
    usage
    exit 0
fi

VIVADO_PATH="$1"

if [ ! -x "${VIVADO_PATH}/bin/vivado_lab" ]; then
    die "Invalid path to Vivado top directory ${VIVADO_PATH}/bin/vivado_lab"
fi

VERSION="$(basename ${VIVADO_PATH})"
if [ "${VERSION}" != "${EXPVER}" ]; then
    die "Not a ${EXPVER} version" 
fi

SCRIPTDIR=$(abspath $(dirname $0))
if [ ! -f "${SCRIPTDIR}/vivadolab.lst" ]; then
    die "Missing tar list file"
fi

TARFILE="${SCRIPTDIR}/vivado_lab_${EXPVER}.tar.xz"
TAGVER=$(echo "${EXPVER}" | cut -c3-)

rm -f ${TARFILE}
(cd ${VIVADO_PATH} && \
    tar cf ${TARFILE} --no-recursion -T ${SCRIPTDIR}/vivadolab.lst) \
        || die "Unable to create tar image" 
(cd  ${SCRIPTDIR} && \
    docker build -f vivadolab.dockerfile -t sifive/vivadolab:d10.9-v${TAGVER} .)
rm -f ${TARFILE}
