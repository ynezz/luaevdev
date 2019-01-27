VERBOSE ?=

ifeq ($(OS),Darwin)
	JOBS ?= $(sysctl -n hw.ncpu)
else
	JOBS ?= $(shell nproc)
endif

define build_cross
	-rm -fr build-$(2)
	mkdir build-$(2)
	cd build-$(2) && \
		cmake \
			-D CMAKE_TOOLCHAIN_FILE=cmake/$(1)-$(2).cmake \
			..
	make -j$(JOBS) VERBOSE=$(VERBOSE) -C build-$(2)
endef

help:
	@echo -e '\n Try `make <all|x86|imx6|ar71xx>`\n'

all: x86 x86-gcc-8 imx6 ar71xx

x86-gcc-8:
	make x86 CC=gcc-8

x86:
	-rm -fr build-x86
	mkdir build-x86
	cd build-x86 && \
		CC=$(CC) \
		cmake -D CMAKE_BUILD_TYPE=Debug ..
	make -j$(JOBS) VERBOSE=$(VERBOSE) -C build-x86

imx6:
	$(call build_cross,openwrt-toolchain,$@)

ar71xx:
	$(call build_cross,openwrt-toolchain,$@)

clean:
	@-rm -fr build-*
