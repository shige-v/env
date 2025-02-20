#pragma once

#include <stdint.h>
#include <stdbool.h>

#if __riscv_xlen == 64
typedef uint64_t addr_t;
#else
typedef uint32_t addr_t;
#endif

//
#define UNUSED(x) ((void)x)

//
#define __read_csr(reg) ({ register uint32_t __tmp; \
      asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
      __tmp; })

#define __write_csr(reg, val) ({ \
      asm volatile ("csrw " #reg ", %0" :: "rK"(val)); })

#define __swap_csr(reg, val) ({ register uint32_t __tmp; \
      asm volatile ("csrrw %0, " #reg ", %1" : "=r"(__tmp) : "rK"(val)); \
      __tmp; })

#define __set_csr(reg, bit) ({ register uint32_t __tmp; \
      asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
      __tmp; })

#define __clear_csr(reg, bit) ({ register uint32_t __tmp; \
      asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
      __tmp; })

#define read_csr(reg)        __read_csr(reg)
#define write_csr(reg, val)  __write_csr(reg, val)
#define swap_csr(reg, val)   __swap_csr(reg, val)
#define set_csr(reg, bit)    __set_csr(reg, bit)
#define clear_csr(reg, bit)  __clear_csr(reg, bit)

#define nop() asm volatile ("nop");

#define wfi() asm volatile ("wfi");

static inline
void write32(addr_t adr, uint32_t dat)
{
  (*(volatile uint32_t *)adr) = dat;
}

static inline
uint32_t read32(addr_t adr)
{
  return (*(volatile uint32_t *)adr);
}

static inline
void write16(addr_t adr, uint16_t dat)
{
  (*(volatile uint16_t *)adr) = dat;
}

static inline
uint16_t read16(addr_t adr)
{
  return (*(volatile uint16_t *)adr);
}

static inline
void write8(addr_t adr, uint8_t dat)
{
  (*(volatile uint8_t *)adr) = dat;
}

static inline
uint8_t read8(addr_t adr)
{
  return (*(volatile uint8_t *)adr);
}
