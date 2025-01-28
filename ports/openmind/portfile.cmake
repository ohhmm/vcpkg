vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ohhmm/openmind
    REF 3f48e0c1b508608c3115dcba6d14d75e833f6833
    SHA512 65059f9e6eff02ee5d0996f86cdbccac0505b1c7961e8048c22f518ae6467502bb8f96f22f3bdc6a576a3b67b2896eb1d93002b4974ff07254e219422d92ef07
    HEAD_REF main
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DOPENMIND_USE_OPENCL=OFF
        -DBUILD_SHARED_LIBS=OFF
)

vcpkg_cmake_install()

# Skip vcpkg_cmake_config_fixup() since the package doesn't generate CMake config files yet
# vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
