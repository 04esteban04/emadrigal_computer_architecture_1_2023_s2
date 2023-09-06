.section .text
.global newx

newx:
    @ Calculo de X'
    add r4, r4, #1          @ Incrementa Ax
    
    vdiv.f32 s9, s12, s10   @ (2*pi)/Lx

    vmov s8, r2             @ Valor de Y actual
    vcvt.f32.s32 s8, s8     @ Convertir a float

    vmul.f32 s8, s9, s8     @ (2*pi*Y)/Lx

    mov r6, #1              @ Flag de retorno
    b sen_start             @ Se obtiene sen(y) (resultado en s5)

    vmov s0, r4             @ Ax en s0
    vcvt.f32.s32 s0, s0     

    vmul.f32 s1, s0, s5     @ Ax*sen(y) en s1

    vmov s2, r3             @ X actual en s2
    vcvt.f32.s32 s2, s2     

    vadd.f32 s6, s2, s1     @ x + Ax*sen(y) en s6

newx_exit:
    @ Termina el programa
    @bx lr
    ldr pc, =0x85f4   @ Carga la dirección en el Program Counter (PC)
