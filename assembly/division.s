.section .text
.global _start

_start:
    mov r0, #13             @ valor de numerador
    vmov s0, r0

    mov r1, #5              @ valor de denominador
    vmov s1, r1  

    vdiv.f32 s2, s0, s1     @ numerador/denominador

    vcvtr.s32.f32 s2, s2    @ Convierte y redondea hacia el entero más cercano
    vmov r2, s2

_exit:
    @ Termina el programa
    mov r0, #0
    mov r7, #1       @ syscall para salir
    svc 0x00
