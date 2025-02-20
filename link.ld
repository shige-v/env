/* link.ld sample  */

OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  . = addr_base_exmem;
  .text.init : { *(.text.init) }
  . = ALIGN(0x100);
  .text : { *(.text) }

  . = ALIGN(0x100);
  .data  : { *(.data) }
  .sdata : {
    PROVIDE(__global_pointer$ = . + 0x800);
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }
  .sbss : {
    PROVIDE(__bss_begin = .);
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }
  .bss : {
    *(.bss .bss.*)
    PROVIDE(__bss_end = .);
  }
  _end = .;  /* for riscv-tests */
  .stack (NOLOAD) : ALIGN (16) {
    PROVIDE(__stack_begin = .);
    . += 0x1000;
    PROVIDE(__stack_end   = .);
  }

  . = addr_base_htifram;
  .tohost : { *(.tohost) }
  /* . += (0x8*agent_id) */
  .simenv_sync : { *(.simenv_sync) }
}

