.macro transfer_xregs op
#if __riscv_32e == 1
    .irp NUM,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
#else
    .irp NUM,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
#endif
        .if     \op == clr
    li  x\NUM, 0
        .elseif \op == sw || \op == lw
    \op x\NUM, \NUM * 4 (sp)
        .elseif \op == sd || \op == ld
    \op x\NUM, \NUM * 8 (sp)
        .else
            .error "instructions not accepted"
        .endif
    .endr
.endm

.macro transfer_fregs rs
    .irp NUM,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
#if __riscv_xlen == 64
    fmv.w.x  f\NUM, \rs
#else
    fmv.s.x  f\NUM, \rs
#endif
    .endr
.endm

# trap handler preprocess
.macro trap_pre_proc
    addi sp, sp, -272

#if __riscv_xlen == 64
    transfer_xregs sd
#else
    transfer_xregs sw
#endif

    csrr a0, mcause
    csrr a1, mepc
    mv   a2, sp
.endm

# trap handler postprocess
.macro trap_post_proc
    csrw mepc, a0

#if __riscv_xlen == 64
    transfer_xregs ld
#else
    transfer_xregs lw
#endif

    addi sp, sp, 272
.endm

    .section ".text.init"
    .globl _start
_start:
    transfer_xregs clr

    # enable FPU if present
    li    t0, 0x00006000           # mstatus.fs
    csrs  mstatus, t0

#ifdef __riscv_flen
    # initialize FPU if we have one
    la    t0, 1f
    csrw  mtvec, t0

    fssr  x0
    transfer_fregs x0
1:
#endif

    # initialize trap vector
    la   t0, trap_entry
    csrw mtvec, t0

    # get hartid
    csrr a0, mhartid

    # initialize global pointer
.option push
.option norelax
    la   gp, __global_pointer$
.option pop

    # initialize tp/sp
    #   give each core 2KB of tp/sp
    la   tp, __stack_begin
    la   sp, __stack_end

    add  a1, a0, 1
    sll  a2, a1, 12
    sub  tp, sp, a2
    sll  a2, a0, 12
    sub  sp, sp, a2

    jal _init

# MT trap entry
    .align 4
    .globl  trap_entry
trap_entry:
    trap_pre_proc
    li   a3, 0       # vec_id
    jal handle_trap
    trap_post_proc
    mret

# NMI trap entry
    .align 4
    .globl  nmi_trap_entry
nmi_trap_entry:
    trap_pre_proc
    li   a3, 0       # vec_id
    jal nmi_handle_trap
    trap_post_proc
    mret

// MT vector table
    .align 7
    .globl vector_table
vector_table:
    j       trap_entry_00
    .align 2
    j       trap_entry_01
    .align 2
    j       trap_entry_02
    .align 2
    j       trap_entry_03
    .align 2
    j       trap_entry_04
    .align 2
    j       trap_entry_05
    .align 2
    j       trap_entry_06
    .align 2
    j       trap_entry_07
    .align 2
    j       trap_entry_08
    .align 2
    j       trap_entry_09
    .align 2
    j       trap_entry_10
    .align 2
    j       trap_entry_11
    .align 2
    j       trap_entry_12
    .align 2
    j       trap_entry_13
    .align 2
    j       trap_entry_14
    .align 2
    j       trap_entry_15
    .align 2
    j       trap_entry_16
    .align 2
    j       trap_entry_17
    .align 2
    j       trap_entry_18
    .align 2
    j       trap_entry_19
    .align 2
    j       trap_entry_20
    .align 2
    j       trap_entry_21
    .align 2
    j       trap_entry_22
    .align 2
    j       trap_entry_23
    .align 2
    j       trap_entry_24
    .align 2
    j       trap_entry_25
    .align 2
    j       trap_entry_26
    .align 2
    j       trap_entry_27
    .align 2
    j       trap_entry_28
    .align 2
    j       trap_entry_29
    .align 2
    j       trap_entry_30
    .align 2
    j       trap_entry_31

    .align 2
trap_entry_00:
    trap_pre_proc
    add     a3, x0, 0
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_01:
    trap_pre_proc
    add     a3, x0, 1
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_02:
    trap_pre_proc
    add     a3, x0, 2
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_03:
    trap_pre_proc
    add     a3, x0, 3
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_04:
    trap_pre_proc
    add     a3, x0, 4
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_05:
    trap_pre_proc
    add     a3, x0, 5
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_06:
    trap_pre_proc
    add     a3, x0, 6
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_07:
    trap_pre_proc
    add     a3, x0, 7
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_08:
    trap_pre_proc
    add     a3, x0, 8
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_09:
    trap_pre_proc
    add     a3, x0, 9
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_10:
    trap_pre_proc
    add     a3, x0, 10
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_11:
    trap_pre_proc
    add     a3, x0, 11
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_12:
    trap_pre_proc
    add     a3, x0, 12
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_13:
    trap_pre_proc
    add     a3, x0, 13
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_14:
    trap_pre_proc
    add     a3, x0, 14
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_15:
    trap_pre_proc
    add     a3, x0, 15
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_16:
    trap_pre_proc
    add     a3, x0, 16
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_17:
    trap_pre_proc
    add     a3, x0, 17
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_18:
    trap_pre_proc
    add     a3, x0, 18
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_19:
    trap_pre_proc
    add     a3, x0, 19
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_20:
    trap_pre_proc
    add     a3, x0, 20
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_21:
    trap_pre_proc
    add     a3, x0, 21
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_22:
    trap_pre_proc
    add     a3, x0, 22
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_23:
    trap_pre_proc
    add     a3, x0, 23
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_24:
    trap_pre_proc
    add     a3, x0, 24
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_25:
    trap_pre_proc
    add     a3, x0, 25
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_26:
    trap_pre_proc
    add     a3, x0, 26
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_27:
    trap_pre_proc
    add     a3, x0, 27
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_28:
    trap_pre_proc
    add     a3, x0, 28
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_29:
    trap_pre_proc
    add     a3, x0, 29
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_30:
    trap_pre_proc
    add     a3, x0, 30
    jal     handle_trap_vec
    trap_post_proc
    mret

    .align 2
trap_entry_31:
    trap_pre_proc
    add     a3, x0, 31
    jal     handle_trap_vec
    trap_post_proc
    mret

    .section ".tohost","aw",@progbits
    .align 6
    .globl tohost
tohost: .dword 0
    .align 6
    .globl fromhost
fromhost: .dword 0
    .section ".simenv_sync","aw",@progbits
    .align 6
    .globl simenv_sync
simenv_sync: .dword 0
