# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/winapi
    REF boost-1.86.0
    SHA512 e03553565112ec318f63bd7af4829f0406c022ce4df5e0d46667971f6b6c7fc5f538644102591bdc864ac71f431efc606592bb457fe40688fdbf911ac064a28c
    HEAD_REF master
)

set(FEATURE_OPTIONS "")
boost_configure_and_install(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
)
