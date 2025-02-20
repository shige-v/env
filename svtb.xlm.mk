#
XLM_CMD   = xrun

BUILD_CMD = $(XLM_CMD)
RUN_CMD   = $(XLM_CMD)

## Build Options
XLM_BUILD_OPT += -64bit -elaborate
XLM_BUILD_OPT += -sv -disable_sem2009
XLM_BUILD_OPT += -timescale '1ns/1ps'
XLM_BUILD_OPT += -uvm -uvmhome CDNS-1.2
XLM_BUILD_OPT += -access +rwc -accessreg +rwc -warn_multiple_driver -libext .v,.sv
#
## for debugging
#XLM_BUILD_OPT += "-parseinfo include"
#
## for fsdb dumpping
XLM_BUILD_OPT += -loadpli1 debpli:novas_pli_boot
## for converting into UVM_ERROR for SVA assertions that have an explicit else $error clause
XLM_BUILD_OPT += -loadpli `xmroot`/tools/methodology/UVM/CDNS-1.2/additions/sv/lib/64bit/libcdns_assert2uvm.so:boot
# 
XLM_BUILD_OPT += -nowarn ZROMCW -nowarn STRINT
#
XPROP         ?= off
ifeq ($(strip $(call toupper, $(XPROP))), C)
  XLM_BUILD_OPT += -XPROP C        # C : Compute as Ternary (CAT) Mode
endif
ifeq ($(strip $(call toupper, $(XPROP))), F)
  XLM_BUILD_OPT += -XPROP F        # F : Forward Only X (FOX) Mode
endif

## Runtime Options
XLM_RUN_OPT = \
  -R \
  -64bit \
  -nocopyright \
  -ieee1364    \
  -nowarn RNDXCELON \
  -seed $(SEED) \
  -licqueue

ifeq ($(strip $(call toupper, $(WAVE))), SHM)
  XLM_RUN_OPT += -tcl -input ${MAKEFILE_DIR}/xlm_run.tcl
endif

# Code/Functional Coverage
XLM_COVDUT  ?= $(TB_TOP)
XLM_COVFILE ?= ./cfg/common_opts.ccf
ifeq ($(strip $(call toupper, $(COVERAGE))), ON)
  # - Build Options for Covearge
  XLM_BUILD_OPT += -coverage all
  XLM_BUILD_OPT += -covdut  $(XLM_COVDUT)
  XLM_BUILD_OPT += -covfile $(XLM_COVFILE)
  # - Runtime Options for Covearge
  XLM_RUN_OPT += -covtest $(TESTNAME) -covoverwrite
endif

ifneq (0, $(USE_CDN_VIP))
  # Components
  XLM_BUILD_OPT += -DDENALI_SV_NC
  XLM_BUILD_OPT += -cdn_vip_root $(CDN_VIP_ROOT)
  XLM_BUILD_OPT += -cdn_viplib
  XLM_BUILD_OPT += -cdn_vip_svlib

  # - Default runtime options for DENALI(CDN)-VIP's
  ifneq ("", $(DENALIRC))
    export DENALIRC=${MAKEFILE_DIR}/denalirc
  endif
endif

# Turning off assertions during a simulation.
ABVOFF_FILE_NAME ?= assertions.txt
ABVOFF_FILE      ?= $(SW_PATH)/$(PATTERN)/$(ABVOFF_FILE_NAME)
ifneq ("","$(wildcard $(ABVOFF_FILE))")
  XLM_RUN_OPT += -abvoff $(ABVOFF_FILE)
endif

#
    clean-files += *.err *.log *.elog sim_result.db cdn_vip_dpi_header.h
distclean-files += xrun.key imc.log mdv.log
    clean-dirs  += xcelium.d waves.shm .bpad
distclean-dirs  += cov_work .simvision

