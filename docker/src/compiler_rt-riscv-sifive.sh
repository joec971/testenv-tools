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

clang_version="$(clang --version 2>&1 | head -1 | cut -d' ' -f3)"

xcfeatures="-ffunction-sections -fdata-sections -fno-stack-protector -fvisibility=hidden"

jobs=$(nproc)
for xlen in ${XLENS}; do
    for isa in ${ISAS}; do
        if echo "${isa}" | grep -q "e"; then
            if [ ${xlen} -eq 64 ]; then
                # no E extension for RV64
                continue
            fi
            xabix="e"
        elif echo "${isa}" | grep -q "d"; then
            xabix="d"
        elif echo "${isa}" | grep -q "f"; then
            xabix="f"
        else
            xabix=""
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
        xsysroot="${prefix}/${clang_version}/riscv64-unknown-elf/${xarchdir}/${xabi}${xlen}${xabix}"
        xcflags="${xctarget} ${xopts} ${xcfeatures}"
        buildpath="/toolchain/build"

        if echo "${xarch}" | grep -Eq '0p[0-9]+'; then
            # clang does not accept non-ratified extensions w/o this flag
            xcflags="${xcflags} -menable-experimental-extensions"
        fi

        echo "--- cleanup ---"
        rm -rf ${buildpath}

        echo "--- compiler-rt ${xarch}/${xabi}${xlen}${xabix} ---"
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
          -DCMAKE_C_COMPILER=${CLANGPATH}/bin/clang         \
          -DCMAKE_CXX_COMPILER=${CLANGPATH}/bin/clang++     \
          -DCMAKE_LINKER=${CLANGPATH}/bin/clang             \
          -DCMAKE_AR=${CLANGPATH}/bin/llvm-ar               \
          -DCMAKE_RANLIB=${CLANGPATH}/bin/llvm-ranlib       \
          -DCMAKE_C_COMPILER_TARGET=${xtarget}              \
          -DCMAKE_ASM_COMPILER_TARGET=${xtarget}            \
          -DCMAKE_SYSROOT=${xsysroot}                       \
          -DCMAKE_SYSROOT_LINK=${xsysroot}                  \
          -DCMAKE_C_FLAGS="${xcrtflags}"                    \
          -DCMAKE_ASM_FLAGS="${xcrtflags}"                  \
          -DCMAKE_CXX_FLAGS="${xcrtflags}"                  \
          -DCMAKE_EXE_LINKER_FLAGS="-L${xsysroot}/lib"      \
          -DLLVM_CONFIG_PATH=${CLANGPATH}/bin/llvm-config   \
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
          -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=OFF          \
          -DCOMPILER_RT_INCLUDE_TESTS=OFF                   \
          -DCOMPILER_RT_USE_LIBCXX=ON                       \
          -DUNIX=1                                          \
          /toolchain/llvm/compiler-rt
        ninja
        ninja install
        mv ${xsysroot}/lib/baremetal/* ${xsysroot}/
        rm -rf ${xsysroot}/lib

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
    echo "--- library source files ---"
    sort -u ${buildpath}/srcfiles.tmp | grep -E '/compiler-rt/' |
      sed "s%^${prefix}/${xtarget}/%%" > ${buildpath}/compiler-rt.files
    sort -u ${buildpath}/srcfiles.tmp
    rm ${buildpath}/srcfiles.tmp
    tar cf - -C /toolchain/llvm -T ${buildpath}/compiler-rt.files | \
      tar xf - -C ${prefix}/${xtarget}
fi
