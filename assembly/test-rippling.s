.section .data

pi_value:
    .float 3.14159265358979323846   @ Definición de π
Lx:
    .float 6.28318530717958647692   @ Definición de Lx con valor de 2π
Ly:
    .float 6.28318530717958647692   @ Definición de Ly con valor de 2π
Ax:
    .float 0.0              @ Inicialización de Ax con valor mínimo (0)
Ay:
    .float 0.0              @ Inicialización de Ay con valor mínimo (0)


.section .text
.global _start

_start:
    ldr r0, =Ax             @ Carga la dirección de Ax en r0
    ldr r1, =Ay             @ Carga la dirección de Ay en r1
    ldr r2, =0x0
    ldr r3, =0xf  
    ldr r4, [r0]            @ Carga el valor actual de Ax en r4
    ldr r5, [r1]            @ Carga el valor actual de Ay en r5  
        

increment_loop:
    add r2, r2, #1          @ Incrementar contador en 1
    add r4, r4, #1          @ Incrementa Ax en 1 
    add r5, r5, #1          @ Incrementa Ay en 1
    
    @ Calculo de x' y y'

    

    cmp r2, r3              @ ¿counter < top_counter?
    bge _exit

    cmp r4, #5              @ Compara con el valor máximo
    bge reset_Ax            @ Salta a reset_Ax si es mayor o igual
    
    cmp r5, #10             @ Compara con el valor máximo
    bge reset_Ay            @ Salta a reset_Ay si es mayor o igual

    b increment_loop        @ Vuelve al inicio del bucle

reset_Ax:
    mov r4, #0              @ Reinicia Ax a su valor mínimo
    b increment_loop        @ Vuelve al inicio del bucle

reset_Ay:
    mov r5, #0              @ Reinicia Ay a su valor mínimo
    b increment_loop        @ Vuelve al inicio del bucle

_exit:
    @ Termina el programa
    mov r0, #0
    mov r7, #1       @ syscall para salir
    svc 0x00 
