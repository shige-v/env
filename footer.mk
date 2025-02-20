#'
escsq  = $(subst $(squote),'\$(squote)',$1)

define cmd
	 @$(if $($(quiet)cmd_$(1)),\
	echo '  $(call escsq,$($(quiet)cmd_$(1)))$(echo-why)';) $(cmd_$(1))

endef

quiet_cmd_clean    = CLEAN-F $(2)
      cmd_clean    = rm -f $(2)
quiet_cmd_cleandir = CLEAN-D $(2)
      cmd_cleandir = rm -rf $(2)

clean:
ifneq ($(strip $(clean-files)),)
	+$(foreach f,$(clean-files),$(if $(wildcard $(f)),$(call cmd,clean,$(f))))
endif
ifneq ($(strip $(clean-dirs)),)
	+$(foreach d,$(clean-dirs),$(if $(wildcard $(d)),$(call cmd,cleandir,$(d))))
endif
	@:

distclean: clean
ifneq ($(strip $(distclean-files)),)
	+$(foreach f,$(distclean-files),$(if $(wildcard $(f)),$(call cmd,clean,$(f))))
endif
ifneq ($(strip $(distclean-dirs)),)
	+$(foreach d,$(distclean-dirs),$(if $(wildcard $(d)),$(call cmd,cleandir,$(d))))
endif
	@:

# Add FORCE to the prequisties of a target to force it to be always rebuild(rerun).
PHONY += FORCE
FORCE: ;

.PHONY: $(PHONY)

# delete partically updated files on error
.DELETE_ON_ERROR:

# do not delete intermediate files automatically
.SECONDARY:

# EOF
