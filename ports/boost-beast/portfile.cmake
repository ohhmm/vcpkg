# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/beast
    REF boost-1.86.0
    SHA512 9f8144e07a44cc5b5be6c6da17b2e6f29f0637dda345764c89eac0bcb9ce2878469a7e6fcd2c96d25034937025768450b33fc14fb40470fa4806bfcf03330e75
    HEAD_REF master
)

set(FEATURE_OPTIONS "")
boost_configure_and_install(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
)
