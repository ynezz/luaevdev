SET(CMAKE_SYSTEM_NAME Linux)

SET(OPENWRT_TOOLCHAIN
	/opt/devel/openwrt/openwrt.git/staging_dir/toolchain-arm_cortex-a9+neon_gcc-7.4.0_musl_eabi/bin/arm-openwrt-linux-muslgnueabi-)

SET(CMAKE_C_COMPILER ${OPENWRT_TOOLCHAIN}gcc)
SET(CMAKE_CXX_COMPILER ${OPENWRT_TOOLCHAIN}g++)

SET(CMAKE_FIND_ROOT_PATH
	/opt/devel/openwrt/openwrt.git/staging_dir/target-arm_cortex-a9+neon_musl_eabi)

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

ADD_DEFINITIONS(
	-mcpu=cortex-a9 -mfpu=neon -g3 -fno-caller-saves -fhonour-copts
	-Wno-error=unused-but-set-variable -Wno-error=unused-result -mfloat-abi=hard
)
