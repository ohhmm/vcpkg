include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ohhmm/openmind
    REF main
    SHA512 3bb72bd43eb546710efa07cca92eee80c5d82d5ce2069366c53a3ff5775228aed193bd138a58132f33bb5386bbe4382b62123685836abeaba4b07d4ddb2055bd
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DOPENMIND_BUILD_SAMPLES=OFF
        -DOPENMIND_BUILD_TESTS=OFF
)

vcpkg_install_cmake()

vcpkg_copy_pdbs()

file(WRITE ${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-cmake-wrapper.cmake
"
set(OPENMIND_DIR \${CURRENT_INSTALLED_DIR})
")

vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/${PORT})
