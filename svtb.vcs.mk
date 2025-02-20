#
BUILD_CMD = vcs
RUN_CMD   = ./simv

DENALI=${CDN_VIP_ROOT}/tools/denali_64bit

## Build Options
VCS_BUILD_OPT += -full64
VCS_BUILD_OPT += -sverilog
VCS_BUILD_OPT += -timescale='1ns/1ps'
VCS_BUILD_OPT += -ntb_opts uvm-1.2 +define+UVM_NO_DEPRECATED
VCS_BUILD_OPT += -xlrm ext_soft_cnst
VCS_BUILD_OPT += +libext+.v+.sv +systemverilogext+.sv
#
## for debugging
#VCS_BUILD_OPT += -V   ## verbose
#
## for fsdb dumpping,  and force_hdl
VCS_BUILD_OPT += -debug_access+all
## for converting into UVM_ERROR for SVA assertions that have an explicit else $error clause
  # --> do not work in VCS sim
#XLM_BUILD_OPT += -loadpli `xmroot`/tools/methodology/UVM/CDNS-1.2/additions/sv/lib/64bit/libcdns_assert2uvm.so:boot
VCS_RUN_OPT   += -load `xmroot`/tools/methodology/UVM/CDNS-1.2/additions/sv/lib/64bit/libcdns_assert2uvm.so
# 
XPROP         ?= off
ifeq ($(strip $(call toupper, $(XPROP))), C)
  #VCS_BUILD_OPT += -XPROP C        # C : Compute as Ternary (CAT) Mode
  $(warning Warning: does not support XPROP option in VCS sim)
endif
ifeq ($(strip $(call toupper, $(XPROP))), F)
  #VCS_BUILD_OPT += -XPROP F        # F : Forward Only X (FOX) Mode
  $(warning Warning: does not support XPROP option in VCS sim)
endif

## Runtime Options
VCS_RUN_OPT += \
  +ntb_random_seed=$(SEED) \
  +vcs+lic+wait \

  #-nowarn RNDXCELON \

ifeq ($(strip $(call toupper, $(WAVE))), SHM)
  #VCS_RUN_OPT += -tcl -input ${MAKEFILE_DIR}/xlm_run.tcl
  $(warning Warning: does not support WAVE=SHM in VCS sim)
endif

# Code/Functional Coverage
VCS_COVDUT  ?= $(TB_TOP)
#VCS_COVFILE ?= ./cfg/common_opts.ccf
ifeq ($(strip $(call toupper, $(COVERAGE))), ON)
  $(warning Warning: no cov file in VCS sim)

  # - Build Options for Covearge
  VCS_BUILD_OPT += -cm line+cond+fsm+tgl+branch+assert  #all

  # - Runtime Options for Covearge
  VCS_RUN_OPT   += -cm line+cond+fsm+tgl+branch+assert  #all
endif

ifneq (0, $(USE_CDN_VIP))
  # Components
  VCS_BUILD_OPT += +define+DENALI_SV_VCS
  VCS_BUILD_OPT += +define+DENALI_UVM
  VCS_BUILD_OPT += +define+VCS
  VCS_BUILD_OPT += -Mupdate
  VCS_BUILD_OPT += -LDFLAGS -Wl,-E 
  VCS_BUILD_OPT += -lca 
  VCS_BUILD_OPT += -CFLAGS '-DVCS -DDENALI_SV_VCS=1 -I../ -I/usr/local/include -I$(DENALI) -I$(DENALI)/ddvapi  -O2 -c' 
  VCS_BUILD_OPT += -LDFLAGS '-rdynamic $(DENALI)/verilog/libcdnsv.so' 
  VCS_BUILD_OPT += -XVpiCbAutoRelease=libcdnsv.so 
  VCS_BUILD_OPT += -P $(DENALI)/verilog/cdnsv.tab 
  VCS_BUILD_OPT += -LDFLAGS '-rdynamic $(DENALI)/lib/libviputil.so' 

  VCS_BUILD_OPT += +incdir+$(DENALI)/ddvapi/sv 
  VCS_BUILD_OPT += $(DENALI)/ddvapi/sv/denaliMemSvIf.c 
  VCS_BUILD_OPT += $(DENALI)/ddvapi/sv/denaliCdn_apbSvIf.c 
  VCS_BUILD_OPT += $(DENALI)/ddvapi/sv/denaliCdn_ahbSvIf.c 
  VCS_BUILD_OPT += $(DENALI)/ddvapi/sv/denaliJtagSvIf.c 

  # - Default runtime options for DENALI(CDN)-VIP's
  ifneq ("", $(DENALIRC))
    export DENALIRC=${MAKEFILE_DIR}/denalirc
  endif
endif

# Turning off assertions during a simulation.
ABVOFF_FILE_NAME ?= assertions.txt
ABVOFF_FILE      ?= $(SW_PATH)/$(PATTERN)/$(ABVOFF_FILE_NAME)
ifneq ("","$(wildcard $(ABVOFF_FILE))")
  #VCS_RUN_OPT += -abvoff $(ABVOFF_FILE)
  $(warning Warning: does not support ABVOFF_FILE option in VCS sim)
endif

#
    clean-files += *.err *.log *.elog sim_result.db cdn_vip_dpi_header.h simv
distclean-files += vcs.key imc.log mdv.log
    clean-dirs  += csrc simv.daidir simv.vdb dump.fsdb .bpad
distclean-dirs  += simv.vdb nWaveLog verdiLog

