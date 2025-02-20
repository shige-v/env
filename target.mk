CONFIG ?= default

XLEN  ?= 32
#MARCH ?= rv32imaf
#MABI  ?= ilp32f

common_dir      := $(MAKEFILE_DIR)
common_arch_dir := $(MAKEFILE_DIR)/$(testname)

#
.DEFAULT_GOAL := all
include $(TOP_DIR)/common/mk/tests.mk

#-------------------------------------------------------------------------------
#

USER_LDFLAGS += \
    -Wl,--defsym -Wl,addr_base_exmem=$(TB_MEMMAP_EXRAM_BASE)   \
    -Wl,--defsym -Wl,addr_base_htifram=$(TB_MEMMAP_HTIFRAM_BASE)


