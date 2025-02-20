MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
COMMON_DIR   := $(shell dirname $(MAKEFILE_DIR))
TOP_DIR      := $(shell dirname $(COMMON_DIR))
DUT_NAME     ?= ns31a
CONFIG       ?= 

include $(MAKEFILE_DIR)/header.mk
include $(TOP_DIR)/config/$(CONFIG)/$(DUT_NAME)_param.mk
# ===================================================================================================================================

ifeq ($(origin RISCV), undefined)
  $(error Environment 'RISCV' undefned)
endif

export PATH:=${RISCV}/bin:${PATH}
export LD_LIBRARY_PAT:=${RISCV}/bin:${LD_LIBRARY_PATH}

XLEN       ?= 32
src_dir    ?= .

MARCH             ?= rv32ima
MABI              ?= ilp32

#
pattern  := $(patsubst $(TOP_DIR)/tests/%,%,$(realpath $(CURDIR)))
testname := $(notdir $(realpath $(CURDIR)))

$(warning testname = $(testname))

pf_common_dir   ?= $(TOP_DIR)/common/src
common_dir      ?= $(COMMON_DIR)
common_arch_dir ?= $(COMMON_DIR)/$(testname)

#--------------------------------------------------------------------
# Macros
#--------------------------------------------------------------------

target    ?= $(testname).riscv
link_file ?= $(common_arch_dir)/link.ld

incs      ?=
incs      += -I$(src_dir) -I$(pf_common_dir) -I$(common_dir) \
             -I$(common_arch_dir) -I$(TOP_DIR)/config/$(CONFIG)

srcs_suffix = .c .S .s
srcs      ?= $(wildcard *.S *.s *.c)
srcs      += $(pf_common_dir)/crt.S $(pf_common_dir)/syscalls.c $(pf_common_dir)/sim_task.c
srcs      += $(common_arch_dir)/$(testname)_common.c
$(warning srcs = $(srcs))

objs      := $(notdir $(filter %.o,$(foreach suf,$(srcs_suffix),$(subst $(suf),.o,$(srcs)))))

depends    = .depends

clean-files += $(objs)
clean-files += $(target) $(target).srec $(target).dump $(target).map 
clean-files += $(depends)

#--------------------------------------------------------------------

OPTIMIZE_OPTS     ?= -O2

RISCV_GCC_OPTS    ?= -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 \
	-O2 -ffast-math -fno-common -fno-builtin-printf -fno-tree-loop-distribute-patterns \
	-g3 -Wall -Wno-unused-variable -Wno-unused-but-set-variable -fno-delete-null-pointer-checks

RISCV_LINK_OPTS   ?= -static -nostdlib -nostartfiles -lm -lgcc -T $(link_file) -Wl,-Map=$(target).map
RISCV_OBJDUMP_OPT ?= --headers --source --disassemble-all --disassemble-zeroes --demangle
#--section=.text --section=.text.startup --section=.text.init --section=.data

#
CROSS_COMPILE ?= $(RISCV)/bin/riscv$(XLEN)-unknown-elf-

AS		= $(CROSS_COMPILE)as
LD		= $(CROSS_COMPILE)gcc
CC		= $(CROSS_COMPILE)gcc
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm
OBJCOPY	= $(CROSS_COMPILE)objcopy
OBJDUMP	= $(CROSS_COMPILE)objdump

CFLAGS  += -march=$(MARCH) -mabi=$(MABI) $(OPTIMIZE_OPTS) $(RISCV_GCC_OPTS)  $(USER_CFLAGS)  $(incs)
LDFLAGS += -march=$(MARCH) -mabi=$(MABI)                  $(RISCV_LINK_OPTS) $(USER_LDFLAGS)

OBJDUMPFLAGS = $(RISCV_OBJDUMP_OPT)  $(USER_OBJDUMPFLAGS)
OBJCOPYFLAGS = -F srec --srec-forceS3 $(USER_OBJCOPYFLAGS)

#--------------------------------------------------------------------
# Rules
#--------------------------------------------------------------------
all: $(all-prerule) $(depends) $(target) $(target).dump $(target).srec $(all-postrule)

quiet_cmd_as = AS       $@
      cmd_as = $(CC) $(CFLAGS) -c $< -o $@
%.o: %.S
	+$(call cmd,as)
%.o: %.s
	+$(call cmd,as)
%.o: $(pf_common_dir)/%.s
	+$(call cmd,as)
%.o: $(pf_common_dir)/%.S
	+$(call cmd,as)

quiet_cmd_cc = CC       $@
      cmd_cc = $(CC) $(CFLAGS) -c $< -o $@
%.o: %.c
	+$(call cmd,cc)
%.o: $(pf_common_dir)/%.c
	+$(call cmd,cc)
%.o: $(common_arch_dir)/%.c
	+$(call cmd,cc)

quiet_cmd_ld = LD       $@
      cmd_ld = $(LD) $(objs) -o $@ $(LDFLAGS)
$(target): $(objs) $(link_file)
	+$(call cmd,ld)

quiet_cmd_objcopy = OBJCOPY  $@
      cmd_objcopy = $(OBJCOPY) $(OBJCOPYFLAGS) $< $@
$(target).srec: $(target)
	+$(call cmd,objcopy)

quiet_cmd_objdump = OBJDUMP  $@
      cmd_objdump = $(OBJDUMP) $(OBJDUMPFLAGS) $< > $@
$(target).dump: $(target)
	+$(call cmd,objdump)

quiet_cmd_depend = DEPEND   $@
      cmd_depend = $(CC) -MM $(srcs) $(CFLAGS) > $@
$(depends):
	+$(call cmd,depend)
PHONY += $(depends)

#--------------------------------------------------------------------
-include $(depends)

# ===================================================================================================================================
include $(MAKEFILE_DIR)/footer.mk

