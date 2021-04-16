#!/bin/sh

set -ex

if [ -z "${xlen}" ]; then
    echo "xlen not defined" >&2
    exit 1
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
if [ -z "${xtarget}" ]; then
    echo "xtarget not defined" >&2
    exit 1
fi
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

export CC_FOR_TARGET="${CLANG11PATH}/bin/clang"
export AR_FOR_TARGET="${CLANG11PATH}/bin/llvm-ar"
export NM_FOR_TARGET="${CLANG11PATH}/bin/llvm-nm"
export RANLIB_FOR_TARGET="${CLANG11PATH}/bin/llvm-ranlib"
export READELF_FOR_TARGET="${CLANG11PATH}/bin/llvm-readelf"
export AS_FOR_TARGET="${CLANG11PATH}/bin/clang"

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

for abi in i ia iac im imac iaf iafd imf imfd imafc imafdc; do
    if echo "${abi}" | grep -q "d"; then
        fp="d"
        newlib_float=""
    elif echo "${abi}" | grep -q "f"; then
        fp="f"
        newlib_float=""
    else
        fp=""
        # assume no float support, not even soft-float in printf functions. YMMV
        newlib_float="${newlib_nofp}"
    fi

    xarch="rv${xlen}${abi}"
    xctarget="-march=${xarch} -mabi=${xabi}${xlen}${fp} ${xmodel}"
    xarchdir="${xarch}"
    xsysroot="${prefix}/${xtarget}/${xarchdir}"
    xcxx_inc="-I${xsysroot}/include"
    xcxx_lib="-L${xsysroot}/lib"
    xcflags="${xctarget} ${xopts} ${xcfeatures}"
    xcxxflags="${xctarget} ${xopts} ${xcxxfeatures} ${xcxxdefs} ${xcxx_inc}"
    buildpath="/toolchain/build"

    echo "--- cleanup ---"
    rm -rf ${buildpath}

    echo "--- newlib ${xarch}/${xabi}${xlen}${fp} ---"
    mkdir -p ${buildpath}/newlib
    xncflags="${xcflags} -fdebug-prefix-map=/toolchain/newlib=${prefix}/${xtarget}"
    export CFLAGS_FOR_TARGET="-target ${xtarget} ${xncflags} -Wno-unused-command-line-argument"
    cd ${buildpath}/newlib
    /toolchain/newlib/configure                 \
        --host=${host}                          \
        --build=${host}                         \
        --target=${xtarget}                     \
        --prefix=${xsysroot}                    \
        ${newlib_default} ${newlib_io} ${newlib_float}
    make -j${jobs}
    make -j1 install
    mv ${xsysroot}/${xtarget}/* ${xsysroot}/
    rmdir ${xsysroot}/${xtarget}

    echo "--- compiler-rt ${xarch}/${xabi}${xlen}${fp} ---"
    mkdir -p ${buildpath}/compiler-rt
    xcrtflags="${xcflags} -fdebug-prefix-map=/toolchain/llvm/compiler-rt=${prefix}/${xtarget}/compiler-rt"
    cd ${buildpath}/compiler-rt
    cmake                                               \
      -G Ninja                                          \
      -DCMAKE_INSTALL_PREFIX=${xsysroot}                \
      -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY    \
      -DCMAKE_SYSTEM_PROCESSOR=riscv                    \
      -DCMAKE_SYSTEM_NAME=Generic                       \
      -DCMAKE_CROSSCOMPILING=ON                         \
      -DCMAKE_CXX_COMPILER_FORCED=TRUE                  \
      -DCMAKE_BUILD_TYPE=Release                        \
      -DCMAKE_C_COMPILER=${CLANG11PATH}/bin/clang       \
      -DCMAKE_CXX_COMPILER=${CLANG11PATH}/bin/clang++   \
      -DCMAKE_LINKER=${CLANG11PATH}/bin/clang           \
      -DCMAKE_AR=${CLANG11PATH}/bin/llvm-ar             \
      -DCMAKE_RANLIB=${CLANG11PATH}/bin/llvm-ranlib     \
      -DCMAKE_C_COMPILER_TARGET=${xtarget}              \
      -DCMAKE_ASM_COMPILER_TARGET=${xtarget}            \
      -DCMAKE_SYSROOT=${xsysroot}                       \
      -DCMAKE_SYSROOT_LINK=${xsysroot}                  \
      -DCMAKE_C_FLAGS="${xcrtflags}"                    \
      -DCMAKE_ASM_FLAGS="${xcrtflags}"                  \
      -DCMAKE_CXX_FLAGS="${xcrtflags}"                  \
      -DCMAKE_EXE_LINKER_FLAGS="-L${xsysroot}/lib"      \
      -DLLVM_CONFIG_PATH=${CLANG11PATH}/bin/llvm-config \
      -DLLVM_DEFAULT_TARGET_TRIPLE=${xtarget}           \
      -DLLVM_TARGETS_TO_BUILD=RISCV                     \
      -DLLVM_ENABLE_PIC=OFF                             \
      -DCOMPILER_RT_OS_DIR=baremetal                    \
      -DCOMPILER_RT_BUILD_BUILTINS=ON                   \
      -DCOMPILER_RT_BUILD_SANITIZERS=OFF                \
      -DCOMPILER_RT_BUILD_XRAY=OFF                      \
      -DCOMPILER_RT_BUILD_LIBFUZZER=OFF                 \
      -DCOMPILER_RT_BUILD_PROFILE=OFF                   \
      -DCOMPILER_RT_BAREMETAL_BUILD=ON                  \
      -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON              \
      -DCOMPILER_RT_INCLUDE_TESTS=OFF                   \
      -DCOMPILER_RT_USE_LIBCXX=ON                       \
      -DUNIX=1                                          \
      /toolchain/llvm/compiler-rt
    ninja
    ninja install

    mv ${xsysroot}/lib/baremetal/* ${xsysroot}/lib
    rmdir ${xsysroot}/lib/baremetal

    if [ ${debug_build} -ne 0 ]; then
        # extract the list of actually used source files, so they can be copied
        # into the destination tree (so that it is possible to step-debug in
        # the system libraries)
        llvm-dwarfdump ${xsysroot}/lib/*.a | grep DW_AT_decl_file | \
        tr -d ' ' | cut -d'"' -f2 >> ${buildpath}/srcfiles.tmp
    fi
done

if [ ${debug_build} -ne 0 ]; then
    # newlib/ files and compiler-rt are handled one after another, as newlib
    # as an additional directory level
    echo "--- library source files ---"
    sort -u ${buildpath}/srcfiles.tmp | grep -E '/(newlib|libgloss)/' | \
      sed "s%^${prefix}/${xtarget}/%%" |
      (cd /toolchain/newlib; xargs -n 1 realpath --relative-to .) \
         > ${buildpath}/newlib.files
    sort -u ${buildpath}/srcfiles.tmp | grep -E '/compiler-rt/' |
      sed "s%^${prefix}/${xtarget}/%%" > ${buildpath}/compiler-rt.files
    sort -u ${buildpath}/srcfiles.tmp
    rm ${buildpath}/srcfiles.tmp
    tar cf - -C /toolchain/newlib -T ${buildpath}/newlib.files | \
      tar xf - -C ${prefix}/${xtarget}
    tar cf - -C /toolchain/llvm -T ${buildpath}/compiler-rt.files | \
      tar xf - -C ${prefix}/${xtarget}
fi
