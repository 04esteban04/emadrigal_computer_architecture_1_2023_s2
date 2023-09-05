.section .data

pi:
    .float 3.141592         @ Definición de π
Lx:
    .int 400                @ Definición de Lx 
Ly:
    .int 400                @ Definición de Ly 
Ax:
    .int 1                  @ Inicialización de Ax
Ay:
    .int 1                  @ Inicialización de Ay 



.section .text
.global xy

xy:
    push {r0, r1, r4, r5, r6}

    ldr r0, =Ax             @ Carga la dirección de Ax en r0
    ldr r4, [r0]            @ Carga el valor actual de Ax en r4

    ldr r1, =Ay             @ Carga la dirección de Ay en r1
    ldr r5, [r1]            @ Carga el valor actual de Ay en r5  
    
    @mov r2, #8              @ Contador Y 
    @mov r3, #10             @ Contador X
    
    ldr r0, =pi             @ Cargar pi en s0
    vldr s0, [r0]

    mov r0, #2              @ Cargar un 2 en s1
    vmov s1, r0
    vcvt.f32.s32 s1, s1

    vmul.f32 s12, s1, s0    @ Cargar un 2*pi en s0

    ldr r0, =Lx             
    ldr r1, [r0]
    vmov s10, r1            @ Cargar Lx en s10
    vcvt.f32.s32 s10, s10

    ldr r0, =Ly     
    ldr r1, [r0]
    vmov s11, r1            @ Cargar Ly en s11
    vcvt.f32.s32 s11, s11

xy_loop:
    cmp r4, #3              @ Compara Ax con el valor máximo
    bge reset_Ax            @ Salta a reset_Ax si es mayor o igual
    
    cmp r5, #3              @ Compara Ay con el valor máximo
    bge reset_Ay            @ Salta a reset_Ay si es mayor o igual

    b newx                 @ Se obtiene el x' en s6
    add r0, r0, #0          @ Intrucción de control

    b newy                 @ Se obtiene el y' en s7
    add r0, r0, #0          @ Intrucción de control
    
    b xy_exit

reset_Ax:
    mov r4, #0              @ Reinicia Ax a su valor mínimo
    b xy_loop               @ Vuelve al inicio del bucle

reset_Ay:
    mov r5, #0              @ Reinicia Ay a su valor mínimo
    b xy_loop               @ Vuelve al inicio del bucle


xy_exit:
    pop {r0, r1, r4, r5, r6}
    @bx lr

    ldr pc, =0x80a8   @ Carga la dirección en el Program Counter (PC)


    @ Termina el programa
    @mov r0, #0
    @mov r7, #1       @ syscall para salir
    @svc 0x00
