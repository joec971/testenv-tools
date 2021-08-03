#!/bin/sh

set -ex

XLENS="32 64"
# ec eac     emac
#        imc imac imafc      imafdc
# ic iac imc imac imafc imfc imafdc
# ISAS="ec eac emac ic iac imc imac imfc imafc imafdc"

# LLVM does not yet support RV32E
ISAS="ic iac imc imac imfc imafc imafdc"
for isa in ${ISAS}; do
    # clang needs the experimental extension version
    ZB_ISAS="${ZB_ISAS} ${isa}_zba0p93_zbb0p93"
done
ISAS="${ISAS} ${ZB_ISAS}"

if [ -z "${prefix}" ]; then
    echo "prefix not defined" >&2
    exit 1
fi

host=$(cc -dumpmachine)
if [ -n "${build}" -a "${build}" = "DEBUG" ]; then
    xopts="-g -Og"
    debug_build=1
else
    xopts="-Os"
    debug_build=0
fi

xcfeatures="-ffunction-sections -fdata-sections -fno-stack-protector -fvisibility=hidden"
xcxxfeatures="${xcfeatures} -fno-use-cxa-atexit"

xcxxdefs="-D_LIBUNWIND_IS_BAREMETAL=1 -D_GNU_SOURCE=1 -D_POSIX_TIMERS=1"
xcxxdefs="${xcxxdefs} -D_LIBCPP_HAS_NO_LIBRARY_ALIGNED_ALLOCATION"
xcxxnothread="-D_LIBCPP_HAS_NO_THREADS=1"

export CC_FOR_TARGET="${CLANGPATH}/bin/clang"
export AR_FOR_TARGET="${CLANGPATH}/bin/llvm-ar"
export NM_FOR_TARGET="${CLANGPATH}/bin/llvm-nm"
export RANLIB_FOR_TARGET="${CLANGPATH}/bin/llvm-ranlib"
export READELF_FOR_TARGET="${CLANGPATH}/bin/llvm-readelf"
export AS_FOR_TARGET="${CLANGPATH}/bin/clang"

newlib_default="\
    --disable-malloc-debugging              \
    --disable-newlib-atexit-dynamic-alloc   \
    --disable-newlib-fseek-optimization     \
    --disable-newlib-fvwrite-in-streamio    \
    --disable-newlib-iconv                  \
    --disable-newlib-mb                     \
    --disable-newlib-supplied-syscalls      \
    --disable-newlib-wide-orient            \
    --disable-nls                           \
    --enable-lite-exit                      \
    --enable-newlib-multithread             \
    --enable-newlib-reent-small             \
    --enable-newlib-nano-malloc             \
    --enable-newlib-global-atexit           \
    --disable-newlib-unbuf-stream-opt"
newlib_nofp="--disable-newlib-io-float"
if [ -z "${NEWLIB_NANO_IO}" ]; then
    # default to larger printf family functions, with C99 support
    newlib_io="\
        --enable-newlib-io-long-long        \
        --enable-newlib-io-c99-formats      \
        --disable-newlib-io-long-double     \
        --disable-newlib-nano-formatted-io"
else
    newlib_io="--disable-newlib-nano-formatted-io"
fi

jobs=$(nproc)
for xlen in ${XLENS}; do
    for isa in ${ISAS}; do
        if echo "${isa}" | grep -q "e"; then
            if [ ${xlen} -eq 64 ]; then
                # no E extension for RV64
                continue
            fi
            xabix="e"
            newlib_float="${newlib_nofp}"
        elif echo "${isa}" | grep -q "d"; then
            xabix="d"
            newlib_float=""
        elif echo "${isa}" | grep -q "f"; then
            xabix="f"
            newlib_float=""
        else
            xabix=""
            # assume no float support, not even soft-float in printf functions.
            # YMMV
            newlib_float="${newlib_nofp}"
        fi

        if [ ${xlen} -eq 64 ]; then
            xabi="lp"
            xmodel="-mcmodel=medany"
        elif [ ${xlen} -eq 32 ]; then
            xabi="ilp"
            xmodel="-mcmodel=medlow"
        else
            echo "xlen invalid" >&2
            exit 1
        fi

        xarch="rv${xlen}${isa}"
        xctarget="-march=${xarch} -mabi=${xabi}${xlen}${xabix} ${xmodel}"
        xarchdir="$(echo ${xarch} | sed -E 's/0p[0-9]+//g')"
        xtarget="riscv${xlen}-unknown-elf"
        xsysroot="${prefix}/${xarchdir}/${xabi}${xlen}${xabix}"
        xcflags="${xctarget} ${xopts} ${xcfeatures}"
        buildpath="/toolchain/build"

        if echo "${xarch}" | grep -Eq '0p[0-9]+'; then
            # clang does not accept non-ratified extensions w/o this flag
            xcflags="${xcflags} -menable-experimental-extensions"
        fi

        echo "--- cleanup ---"
        rm -rf ${buildpath}

        echo "--- newlib ${xarch}/${xabi}${xlen}${xabix} ---"
        mkdir -p ${buildpath}/newlib
        xncflags="${xcflags} -fdebug-prefix-map=/toolchain/newlib=${prefix}/${xtarget}"
        export CFLAGS_FOR_TARGET="-target ${xtarget} ${xncflags} -Wno-unused-command-line-argument"
        cd ${buildpath}/newlib
        /toolchain/newlib/configure  \
            --host=${host}           \
            --build=${host}          \
            --target=${xtarget}      \
            --prefix=${prefix}       \
            ${newlib_default} ${newlib_io} ${newlib_float}
        make -j${jobs}
        make -j1 install
        # move to similar dir as GCC multilib toolchain
        mkdir -p ${prefix}/include
        (tar cf - -C ${prefix}/${xtarget}/include . | \
         tar xf - -C ${prefix}/include)
        # remove always present directory, whatever xarch is built
        rm -rf ${prefix}/${xtarget}/lib/rv64imafdc
        mkdir -p ${prefix}/lib/${xarchdir}/${xabi}${xlen}${xabix}
        (tar cf - -C ${prefix}/${xtarget}/lib . | \
         tar xf - -C ${prefix}/lib/${xarchdir}/${xabi}${xlen}${xabix})
        # remove initial installation path
        rm -rf ${prefix}/${xtarget}
        # remove share data to make image lighter
        rm -rf ${prefix}/${xtarget}/share/iconv_data

        if [ ${debug_build} -ne 0 ]; then
            # extract the list of actually used source files, so they can be copied
            # into the destination tree (so that it is possible to step-debug in
            # the system libraries)
            llvm-dwarfdump ${xsysroot}/lib/*.a | grep DW_AT_decl_file | \
            tr -d ' ' | cut -d'"' -f2 >> ${buildpath}/srcfiles.tmp
        fi
    done # isa
done # xlen

if [ ${debug_build} -ne 0 ]; then
    # newlib/ files and compiler-rt are handled one after another, as newlib
    # as an additional directory level
    echo "--- library source files ---"
    sort -u ${buildpath}/srcfiles.tmp | grep -E '/(newlib|libgloss)/' | \
      sed "s%^${prefix}/${xtarget}/%%" |
      (cd /toolchain/newlib; xargs -n 1 realpath --relative-to .) \
         > ${buildpath}/newlib.files
    rm ${buildpath}/srcfiles.tmp
    tar cf - -C /toolchain/newlib -T ${buildpath}/newlib.files | \
      tar xf - -C ${prefix}/${xtarget}
fi
