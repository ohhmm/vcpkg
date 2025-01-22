cmake_minimum_required(VERSION 3.15)
project(spdk C)

# Find required tools
find_program(MESON_EXECUTABLE meson REQUIRED)
find_program(NINJA_EXECUTABLE ninja REQUIRED)
find_program(GIT_EXECUTABLE git REQUIRED)
find_package(PkgConfig REQUIRED)

# Set paths
set(DPDK_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/dpdk-src")
set(DPDK_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/dpdk-build")
set(DPDK_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/dpdk-install")

# Create directories
file(MAKE_DIRECTORY ${DPDK_SOURCE_DIR})
file(MAKE_DIRECTORY ${DPDK_BUILD_DIR})
file(MAKE_DIRECTORY ${DPDK_INSTALL_DIR})
file(MAKE_DIRECTORY ${DPDK_INSTALL_DIR}/lib/pkgconfig)

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

# Configure DPDK with meson
message(STATUS "Configuring DPDK...")
execute_process(
    COMMAND ${CMAKE_COMMAND} -E env
        PKG_CONFIG_PATH=""
        PKG_CONFIG_LIBDIR=""
        ${MESON_EXECUTABLE} setup
            --prefix=${DPDK_INSTALL_DIR}
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
            -Dexperimental_dma_memseg=false
            -Dper_library_versions=false
            -Dcheck_includes=false
            -Ddisable_libs=flexran_sdk,cuda
            -Dbuildtype=release
            ${DPDK_BUILD_DIR}
    WORKING_DIRECTORY ${DPDK_SOURCE}
    RESULT_VARIABLE DPDK_CONFIGURE_RESULT
)

if(NOT DPDK_CONFIGURE_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure DPDK")
endif()

# Build DPDK
message(STATUS "Building DPDK...")
execute_process(
    COMMAND ${NINJA_EXECUTABLE} -C ${DPDK_BUILD_DIR}
    WORKING_DIRECTORY ${DPDK_SOURCE_DIR}
    RESULT_VARIABLE DPDK_BUILD_RESULT
)

if(NOT DPDK_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build DPDK")
endif()

# Install DPDK
message(STATUS "Installing DPDK...")
execute_process(
    COMMAND ${NINJA_EXECUTABLE} -C ${DPDK_BUILD_DIR} install
    WORKING_DIRECTORY ${DPDK_SOURCE_DIR}
    RESULT_VARIABLE DPDK_INSTALL_RESULT
)

if(NOT DPDK_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install DPDK")
endif()

# Generate pkg-config file for DPDK
configure_file(
    "${CMAKE_SOURCE_DIR}/libdpdk.pc.in"
    "${DPDK_INSTALL_DIR}/lib/pkgconfig/libdpdk.pc"
    @ONLY
)

# Configure SPDK
message(STATUS "Configuring SPDK...")

# Create configure script with proper environment variables
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/configure_spdk.sh"
    "#!/bin/bash\n"
    "export PKG_CONFIG_PATH=\"${DPDK_INSTALL_DIR}/lib/pkgconfig\"\n"
    "export PKG_CONFIG_LIBDIR=\"${DPDK_INSTALL_DIR}/lib/pkgconfig\"\n"
    "export PKG_CONFIG_ALLOW_SYSTEM_LIBS=0\n"
    "export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=0\n"
    "export DPDK_DIR=\"${DPDK_INSTALL_DIR}\"\n"
    "export DPDK_LIB_DIR=\"${DPDK_INSTALL_DIR}/lib\"\n"
    "export DPDK_INC_DIR=\"${DPDK_INSTALL_DIR}/include\"\n"
    "${CMAKE_SOURCE_DIR}/configure \\\n"
    "    --prefix=${CMAKE_INSTALL_PREFIX} \\\n"
    "    --disable-tests \\\n"
    "    --disable-unit-tests \\\n"
    "    --disable-examples \\\n"
    "    --disable-apps \\\n"
    "    --with-rdma=verbs \\\n"
    "    --with-shared \\\n"
    "    --with-dpdk=${DPDK_INSTALL_DIR} \\\n"
    "    --without-crypto \\\n"
    "    --without-vhost \\\n"
    "    --without-virtio \\\n"
    "    --without-vfio-user \\\n"
    "    --with-compression \\\n"
    "    --with-dix-generation \\\n"
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
add_custom_target(spdk-configure
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/configure_spdk.sh
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Configuring SPDK"
    VERBATIM
)

# Build SPDK
add_custom_target(spdk ALL
    COMMAND ${CMAKE_MAKE_PROGRAM} -j${CMAKE_BUILD_PARALLEL_LEVEL}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS spdk-configure
    COMMENT "Building SPDK"
    VERBATIM
)

# Install target
install(CODE "execute_process(COMMAND ${CMAKE_MAKE_PROGRAM} install WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})")
