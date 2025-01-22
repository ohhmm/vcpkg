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

# Check for required system packages
vcpkg_list(SET REQUIRED_PACKAGES
    libnuma-dev
    librdmacm-dev
    libibverbs-dev
    libaio-dev
)

foreach(PKG IN LISTS REQUIRED_PACKAGES)
    message(STATUS "Checking for ${PKG}")
    execute_process(
        COMMAND dpkg -l ${PKG}
        OUTPUT_QUIET
        ERROR_QUIET
        RESULT_VARIABLE PKG_NOT_FOUND
    )
    if(PKG_NOT_FOUND)
        message(FATAL_ERROR "Required package ${PKG} not found. Please install using: sudo apt-get install ${PKG}")
    endif()
endforeach()

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
        012-add-meson-options.patch
)

# Configure and build DPDK
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
)

# Configure SPDK
message(STATUS "Configuring SPDK...")
vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTOCONFIG
    OPTIONS
        --prefix=${CURRENT_PACKAGES_DIR}
        --disable-tests
        --disable-unit-tests
        --disable-examples
        --disable-apps
        --with-rdma=verbs
        --with-shared
        --with-dpdk=${CURRENT_PACKAGES_DIR}
        --with-compression
        --with-dix-generation
        --without-crypto
        --without-vhost
        --without-virtio
        --without-vfio-user
        --without-rbd
        --without-ublk
        --without-fc
        --without-daos
        --without-iscsi-initiator
        --without-vtune
        --without-ocf
        --without-uring
        --without-fuse
        --without-nvme-cuse
        --without-raid5f
        --without-wpdk
        --without-usdt
        --without-sma
        --without-avahi
        --without-golang
    DETERMINE_BUILD_TRIPLET
    NO_ADDITIONAL_PATHS
)

# Build and install SPDK
vcpkg_install_make()

# Fix pkgconfig files
vcpkg_fixup_pkgconfig()

# Install copyright and additional files
file(INSTALL "${SOURCE_PATH}/LICENSE" 
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
     RENAME copyright)

file(INSTALL "${SOURCE_PATH}/scripts/setup.sh"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}/scripts")

file(INSTALL "${SOURCE_PATH}/scripts/common.sh"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}/scripts")

if(NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    vcpkg_copy_pdbs()
endif()
