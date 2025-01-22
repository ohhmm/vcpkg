if(NOT VCPKG_TARGET_IS_LINUX)
    message(FATAL_ERROR "Intel SPDK currently only supports Linux platforms")
endif()

vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)

# Find required tools
vcpkg_find_acquire_program(PYTHON3)
vcpkg_find_acquire_program(MESON)
vcpkg_find_acquire_program(NINJA)
vcpkg_find_acquire_program(MAKE)
vcpkg_find_acquire_program(GIT)
vcpkg_find_acquire_program(PKG_CONFIG)

# Install required system packages
vcpkg_execute_required_process(
    COMMAND apt-get update
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
    LOGNAME apt-update
)

vcpkg_execute_required_process(
    COMMAND apt-get install -y libnuma-dev librdmacm-dev libibverbs-dev libaio-dev
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
    LOGNAME apt-install-deps
)

# Download SPDK
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO spdk/spdk
    REF v24.09
    SHA512 f9a51821cf92ba40d656fc3e965fb8d9d35b8fe7c5149334998778b8272e37155e83c7704895a85f61a47b514eff8d52fb86dc63e51da784c2e87509529caaae
    HEAD_REF master
    PATCHES
        001-fix-build-system.patch
        002-fix-configure-pkgconfig.patch
        003-fix-pkg-config-paths.patch
        004-fix-dpdk-pkgconfig.patch
        005-fix-dpdk-detection.patch
        006-fix-dpdk-configure.patch
        007-fix-dpdk-detection-comprehensive.patch
        008-fix-dpdk-detection-final.patch
        009-fix-dpdk-system-detection.patch
        010-fix-dpdk-system-isolation.patch
        011-fix-examples-handling.patch
        012-add-meson-options.patch
)

# Download and extract DPDK
vcpkg_download_distfile(DPDK_ARCHIVE
    URLS "https://fast.dpdk.org/rel/dpdk-23.11.tar.xz"
    FILENAME "dpdk-23.11.tar.xz"
    SHA512 e5177d658fca8df55090a92ea1a8932aac5847314fed7c686b8a36e709f34b14c05e68d6c4c433ff5371b67a39c4324b4eefab8c138f417468f57092bf269b4c
)

vcpkg_extract_source_archive(
    DPDK_SOURCE
    ARCHIVE "${DPDK_ARCHIVE}"
    SOURCE_BASE "dpdk-23.11"
    PATCHES
        001-fix-build-system.patch
        002-fix-configure-pkgconfig.patch
        003-fix-pkg-config-paths.patch
        004-fix-dpdk-pkgconfig.patch
        005-fix-dpdk-detection.patch
        006-fix-dpdk-configure.patch
        007-fix-dpdk-detection-comprehensive.patch
        008-fix-dpdk-detection-final.patch
        009-fix-dpdk-system-detection.patch
        010-fix-dpdk-system-isolation.patch
        011-fix-examples-handling.patch
        012-add-meson-options.patch
)

# Configure and build DPDK
message(STATUS "Building DPDK...")
vcpkg_configure_meson(
    SOURCE_PATH "${DPDK_SOURCE}"
    OPTIONS
        --prefix=${CURRENT_PACKAGES_DIR}
        --buildtype=release
        -Dplatform=generic
        -Dmax_lcores=8
        -Dmax_numa_nodes=1
        -Ddefault_library=shared
        -Dwerror=false
        -Dmachine=native
        -Dexamples=disabled
        -Dtests=disabled
        -Dtools=disabled
        -Denable_kmods=false
        -Ddisable_drivers=crypto,dma,event,baseband,gpu,ml,raw,regex,vdpa,flexran_fec
        -Denable_drivers=net,bus,mempool,ring
        -Dincludedir=${CURRENT_PACKAGES_DIR}/include
        -Dlibdir=${CURRENT_PACKAGES_DIR}/lib
        -Dexperimental_dma_memseg=false
        -Dper_library_versions=false
        -Dcheck_includes=false
        -Ddisable_libs=flexran_sdk,cuda
)

vcpkg_install_meson()

# Generate pkg-config file for DPDK
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/lib/pkgconfig")
configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/libdpdk.pc.in"
    "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libdpdk.pc"
    @ONLY
)

# Configure SPDK
message(STATUS "Configuring SPDK...")

# Create configure script with proper environment variables
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/configure_spdk.sh"
    "#!/bin/bash\n"
    "export PKG_CONFIG_PATH=\"${CURRENT_PACKAGES_DIR}/lib/pkgconfig\"\n"
    "export PKG_CONFIG_LIBDIR=\"${CURRENT_PACKAGES_DIR}/lib/pkgconfig\"\n"
    "export PKG_CONFIG_SYSROOT_DIR=\"${CURRENT_PACKAGES_DIR}\"\n"
    "export PKG_CONFIG_ALLOW_SYSTEM_LIBS=0\n"
    "export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=0\n"
    "export PKG_CONFIG_SYSTEM_LIBRARY_PATH=\"\"\n"
    "export PKG_CONFIG_SYSTEM_INCLUDE_PATH=\"\"\n"
    "export DPDK_DIR=\"${CURRENT_PACKAGES_DIR}\"\n"
    "export DPDK_LIB_DIR=\"${CURRENT_PACKAGES_DIR}/lib\"\n"
    "export DPDK_INC_DIR=\"${CURRENT_PACKAGES_DIR}/include\"\n"
    "export DPDK_PKG_CONFIG_PATH=\"${CURRENT_PACKAGES_DIR}/lib/pkgconfig\"\n"
    "${SOURCE_PATH}/configure \\\n"
    "    --prefix=${CURRENT_PACKAGES_DIR} \\\n"
    "    --disable-tests \\\n"
    "    --disable-unit-tests \\\n"
    "    --disable-examples \\\n"
    "    --disable-apps \\\n"
    "    --with-rdma=verbs \\\n"
    "    --with-shared \\\n"
    "    --with-dpdk=${CURRENT_PACKAGES_DIR} \\\n"
    "    --without-crypto \\\n"
    "    --without-fio \\\n"
    "    --without-xnvme \\\n"
    "    --without-vhost \\\n"
    "    --without-virtio \\\n"
    "    --without-vfio-user \\\n"
    "    --without-vbdev-compress \\\n"
    "    --without-dpdk-compressdev \\\n"
    "    --without-rbd \\\n"
    "    --without-ublk \\\n"
    "    --without-fc \\\n"
    "    --without-daos \\\n"
    "    --without-iscsi-initiator \\\n"
    "    --without-vtune \\\n"
    "    --without-ocf \\\n"
    "    --without-uring \\\n"
    "    --without-fuse \\\n"
    "    --without-nvme-cuse \\\n"
    "    --without-raid5f \\\n"
    "    --without-wpdk \\\n"
    "    --without-usdt \\\n"
    "    --without-fuzzer \\\n"
    "    --without-sma \\\n"
    "    --without-avahi \\\n"
    "    --without-golang\n"
)

# Make script executable
execute_process(
    COMMAND chmod +x "${CMAKE_CURRENT_BINARY_DIR}/configure_spdk.sh"
    RESULT_VARIABLE CHMOD_RESULT
)

if(NOT CHMOD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to make configure script executable")
endif()

# Run configure script
vcpkg_execute_required_process(
    COMMAND "${CMAKE_CURRENT_BINARY_DIR}/configure_spdk.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME spdk-configure
)

# Build SPDK
vcpkg_execute_required_process(
    COMMAND make -j${VCPKG_CONCURRENCY}
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME spdk-build
)

# Install SPDK
vcpkg_execute_required_process(
    COMMAND make install
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME spdk-install
)

# Install copyright and additional files
file(INSTALL "${SOURCE_PATH}/LICENSE" 
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
     RENAME copyright)

file(INSTALL "${SOURCE_PATH}/scripts/setup.sh"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}/scripts")

file(INSTALL "${SOURCE_PATH}/scripts/common.sh"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}/scripts")

vcpkg_fixup_pkgconfig()

if(NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    vcpkg_copy_pdbs()
endif()
