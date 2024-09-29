# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/core
    REF boost-1.86.0
    SHA512 36e269dabb7c5c74416d2e55683a7354f47623c726fa95576c8a2c78745e65ce6e9ad5688cc96581f55ba939c00853da30e28d814aef71233080dfcfdb3428f0
    HEAD_REF master
)

set(FEATURE_OPTIONS "")
boost_configure_and_install(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
)
