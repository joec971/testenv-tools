#!/bin/sh

# Build toolchains

SSH_ID="${GITHUB_SSH_ID:=${HOME}/.ssh/id_si5_ed25519}"
SI5_VER="2021.06.3"
ALPINE_VERSION="3.13.5"
NEWLIB_VERSION="4.1.0"

. $(dirname $0)/versions.sh
. $(dirname $0)/funcs.sh

DOCKER_TMPDIR=""
SSH_AGENT_PID=0

ALPINE_VER="$(echo ${ALPINE_VERSION} | cut -d. -f1-2)"
NEWLIB_VER="$(echo ${NEWLIB_VERSION} | cut -d. -f1-2)"

cleanup() {
    if [ -n "${DOCKER_TMPDIR}" ]; then
        if [ -d "${DOCKER_TMPDIR}" ]; then
            info "Cleaning up ${DOCKER_TMPDIR}"
            rm -rf "${DOCKER_TMPDIR}"
        fi
    fi
    if [ ${SSH_AGENT_PID} -ne 0 ]; then
        info "Stop ssh-agent"
        kill ${SSH_AGENT_PID}
    fi
}

trap cleanup EXIT

dockfiles=$(cd docker/src && ls -1 *.dockerfile)

DOCKER_TMPDIR="$(mktemp -d)"

for df in ${dockfiles}; do
    info "Creating $df"
    cat docker/src/$df | \
        sed -e "s/@SI5_VER@/r$SI5_VER/g" \
            -e "s/@SI5_BRANCH@/$SI5_VER/g" \
            -e "s/@ALPINE_VER@/a$ALPINE_VER/g" \
            -e "s/@ALPINE_VERSION@/$ALPINE_VERSION/g" \
            -e "s/@NEWLIB_VER@/n$NEWLIB_VER/g" \
            -e "s/@NEWLIB_VERSION@/$NEWLIB_VERSION/g" \
            -e "s/@BUILD@/RELEASE/g" \
    > ${DOCKER_TMPDIR}/$df || die "Cannot generate $df"
    echo "$df" | grep -Eq "clang-riscv[0-9][0-9]-sifive.dockerfile"
    if [ $? -eq 0 ]; then
        ddf=$(echo "$df" | sed "s/.dockerfile$/-dbg.dockerfile/")
        info "Creating $ddf"
        cat docker/src/$df | \
            sed -e "s/@SI5_VER@/r$SI5_VER/g" \
                -e "s/@SI5_BRANCH@/$SI5_VER/g" \
                -e "s/@ALPINE_VER@/a$ALPINE_VER/g" \
                -e "s/@ALPINE_VERSION@/$ALPINE_VERSION/g" \
                -e "s/@NEWLIB_VER@/n$NEWLIB_VER/g" \
                -e "s/@NEWLIB_VERSION@/$NEWLIB_VERSION/g" \
                -e "s/@BUILD@/DEBUG/g" \
        > ${DOCKER_TMPDIR}/$ddf || die "Cannot generate $ddf"
    fi
done

cat $(dirname $0)/push.sh | \
    sed -e "s/@SI5_VER@/r$SI5_VER/g" \
        -e "s/@SI5_BRANCH@/$SI5_VER/g" \
        -e "s/@ALPINE_VER@/a$ALPINE_VER/g" \
        -e "s/@ALPINE_VERSION@/$ALPINE_VERSION/g" \
        -e "s/@NEWLIB_VER@/n$NEWLIB_VER/g" \
        -e "s/@NEWLIB_VERSION@/$NEWLIB_VERSION/g" \
        -e "s/@BUILD@/RELEASE/g" \
> ${DOCKER_TMPDIR}/push.sh || die "Cannot generate push.sh"

# copy static files
cp docker/src/*.sh docker/src/*.patch docker/bin/versions.sh ${DOCKER_TMPDIR}/

info "Use SSH identity ${SSH_ID}"
eval `ssh-agent -s`
ssh-add ${SSH_ID}

# Docker 18.09+ is required
# SiFive toolchains are only available as private SiFive repository
export DOCKER_BUILDKIT=1

info "Download SiFive LLVM sources"
cd ${DOCKER_TMPDIR} && \
docker build --ssh default -f llvm-src-sifive.dockerfile -t sifive/llvm-src:r${SI5_VER} . \
    || die "Failed to download LLVM toolchain"
info "Download SiFive GCC sources"
cd ${DOCKER_TMPDIR} && \
docker build --ssh default -f gcc-src-sifive.dockerfile -t sifive/gcc-src:r${SI5_VER} . \
    || die "Failed to download GCC toolchain"
info "Download SiFive binutils sources"
cd ${DOCKER_TMPDIR} && \
docker build --ssh default -f binutils-src-sifive.dockerfile -t sifive/binutils-src:r${SI5_VER} . \
    || die "Failed to download binutils toolchain"

# done with private GitHub repos
unset DOCKER_BUILDKIT

info "Download newlib"
cd ${DOCKER_TMPDIR} && \
docker build -f newlib.dockerfile -t newlib-src:v${NEWLIB_VERSION} . \
    || die "Failed to download newlib"

info "Build Binutils"
cd ${DOCKER_TMPDIR} && \
docker build -f binutils-riscv-sifive.dockerfile -t sifive/binutils-riscv:a${ALPINE_VER}-r${SI5_VER} . \
    || die "Failed to build Binutils"
info "Build GDB"
cd ${DOCKER_TMPDIR} && \
docker build -f gdb-riscv-sifive.dockerfile -t sifive/gdb-riscv:a${ALPINE_VER}-r${SI5_VER} . \
    || die "Failed to build GDB"
info "Build LLVM"
cd ${DOCKER_TMPDIR} && \
docker build -f llvm-riscv-sifive.dockerfile -t sifive/llvm-riscv:a${ALPINE_VER}-r${SI5_VER} . \
    || die "Failed to build LLVM toolchain"
info "Build LLVM nano"
cd ${DOCKER_TMPDIR} && \
docker build -f llvm-riscv-sifive-nano.dockerfile -t sifive/llvm-riscv-nano:a${ALPINE_VER}-r${SI5_VER} . \
    || die "Failed to build LLVM nano"
info "Creating Clang image"
cd ${DOCKER_TMPDIR} && \
docker build -f clang-riscv-sifive.dockerfile -t sifive/clang-riscv:a${ALPINE_VER}-r${SI5_VER} . \
    || die "Failed to create Clang image"
info "Build C runtime (RV32, default)"
cd ${DOCKER_TMPDIR} && \
docker build -f clang-riscv32-sifive.dockerfile -t sifive/clang-riscv32:a${ALPINE_VER}-r${SI5_VER}-n${NEWLIB_VER} . \
    || die "Failed to build C runtime"
info "Build C runtime (RV64, default)"
cd ${DOCKER_TMPDIR} && \
docker build -f clang-riscv64-sifive.dockerfile -t sifive/clang-riscv64:a${ALPINE_VER}-r${SI5_VER}-n${NEWLIB_VER} . \
    || die "Failed to build C runtime"
info "Build C runtime (RV32, debug)"
cd ${DOCKER_TMPDIR} && \
docker build -f clang-riscv32-sifive-dbg.dockerfile -t sifive/clang-riscv32_dbg:a${ALPINE_VER}-r${SI5_VER}-n${NEWLIB_VER} . \
    || die "Failed to build C runtime"
info "Build C runtime (RV64, debug)"
cd ${DOCKER_TMPDIR} && \
docker build -f clang-riscv64-sifive-dbg.dockerfile -t sifive/clang-riscv64_dbg:a${ALPINE_VER}-r${SI5_VER}-n${NEWLIB_VER} . \
    || die "Failed to build C runtime"
info "Build GCC toolchain"
cd ${DOCKER_TMPDIR} && \
docker build -f gcc-riscv-sifive.dockerfile -t sifive/gcc-riscv:a${ALPINE_VER}-r${SI5_VER} .
