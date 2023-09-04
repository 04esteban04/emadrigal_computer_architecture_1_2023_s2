.section .text
.global newy

newy:
    @ Calculo de Y'
    add r5, r5, #1          @ Incrementa Ay
    
    vdiv.f32 s13, s12, s11  @ (2*pi)/Ly

    vmov s8, r3             @ Valor de X actual
    vcvt.f32.s32 s8, s8     @ Convertir a float

    vmul.f32 s8, s13, s8    @ (2*pi*Y)/Lx

    mov r6, #0              @ Flag de retorno
    b sen_start             @ Se obtiene sen(x) (resultado en s5)
 
    vmov s0, r5             @ Ay en s0
    vcvt.f32.s32 s0, s0     

    vmul.f32 s1, s0, s5     @ Ay*sen(x) en s1

    vmov s2, r2             @ Y actual en s2
    vcvt.f32.s32 s2, s2     

    vadd.f32 s7, s2, s1     @ y + Ay*sen(x) en s4

newy_exit:
    @ Termina el programa
    @bx lr
    ldr pc, =0x8070   @ Carga la dirección en el Program Counter (PC)
