# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/config
    REF boost-1.86.0
    SHA512 d2ca9b1619905c60d7e2d82afab9570e84834e6d8d742e0a10693fd71319c69d8ad3b5a4c4dad007d8df2840aa8a79786e5e9a53ed2c44395bc319995e86bb9e
    HEAD_REF master
)

set(FEATURE_OPTIONS "")
boost_configure_and_install(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
)
file(APPEND "${CURRENT_PACKAGES_DIR}/include/boost/config/user.hpp" "\n#ifndef BOOST_ALL_NO_LIB\n#define BOOST_ALL_NO_LIB\n#endif\n")
file(APPEND "${CURRENT_PACKAGES_DIR}/include/boost/config/user.hpp" "\n#undef BOOST_ALL_DYN_LINK\n")

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    file(APPEND "${CURRENT_PACKAGES_DIR}/include/boost/config/user.hpp" "\n#define BOOST_ALL_DYN_LINK\n")
endif()
file(COPY "${SOURCE_PATH}/libs/config/checks" DESTINATION "${CURRENT_PACKAGES_DIR}/share/boost-config")
