# Generate pkg-config file for DPDK
set(prefix "${CURRENT_PACKAGES_DIR}")
set(exec_prefix "${prefix}")
set(libdir "${prefix}/lib")
set(includedir "${prefix}/include")
set(VERSION "23.11")

# Create pkg-config file content
set(PC_CONTENT "prefix=${prefix}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include
Name: libdpdk
Description: Data Plane Development Kit (DPDK)
Version: ${VERSION}
Libs: -L\${libdir} -lrte_eal -lrte_mempool -lrte_ring -lrte_mbuf -lrte_bus_pci -lrte_pci -lrte_kvargs
Libs.private: -lnuma -lm -lpthread -ldl -lrt
Cflags: -I\${includedir}/dpdk -march=native")

# Write the pkg-config file
file(WRITE "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libdpdk.pc" "${PC_CONTENT}")
