BUILD_DIR ?= build

ifeq ($(OS),Darwin)
	JOBS ?= $(sysctl -n hw.ncpu)
else
	JOBS ?= $(shell nproc)
endif

.PHONY: clean build

build:
	@cmake --version
	-rm -fr $(BUILD_DIR)
	mkdir $(BUILD_DIR)
	cd $(BUILD_DIR) && cmake .. && make -j$(JOBS) VERBOSE=99

clean:
	-rm -fr $(BUILD_DIR)
