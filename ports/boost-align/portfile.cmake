# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/align
    REF boost-1.86.0
    SHA512 bffa9c6accb4e52fea876aca2fae3ed969f65deff578344c3cce48890650e30981f2010d64f19c642791f1a5d3798198502ebf56582096f0f734d5c2a665bb21
    HEAD_REF master
)

set(FEATURE_OPTIONS "")
boost_configure_and_install(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
)
