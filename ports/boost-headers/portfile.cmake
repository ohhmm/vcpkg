# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/headers
    REF boost-1.86.0
    SHA512 4cd0f4c04fe8891789139ba454aa87c97bbaa2de6ee16dd9fa251ce6902c4c7685dfa00295cbf4c1b7e08b013c0eba3fa87404d1ba363fafb2020d2e9e9064dc
    HEAD_REF master
)

set(FEATURE_OPTIONS "")
boost_configure_and_install(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
)
