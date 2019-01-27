SET(CMAKE_SYSTEM_NAME Linux)

SET(OPENWRT_TOOLCHAIN
	/opt/devel/openwrt/openwrt.git/staging_dir/toolchain-mips_24kc_gcc-7.4.0_musl/bin/mips-openwrt-linux-musl-)

SET(CMAKE_C_COMPILER ${OPENWRT_TOOLCHAIN}gcc)
SET(CMAKE_CXX_COMPILER ${OPENWRT_TOOLCHAIN}g++)

SET(CMAKE_FIND_ROOT_PATH
	/opt/devel/openwrt/openwrt.git/staging_dir/target-mips_24kc_musl)

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

ADD_DEFINITIONS(
	-Os -pipe -mno-branch-likely -mips32r2 -mtune=24kc -fno-caller-saves -fno-plt
	-fhonour-copts -Wno-error=unused-but-set-variable -Wno-error=unused-result
	-msoft-float -mips16 -minterlink-mips16
)
