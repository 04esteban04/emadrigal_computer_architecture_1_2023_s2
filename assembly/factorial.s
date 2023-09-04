.section .text     
.global factorial           @ Define la función global "factorial"

factorial:
    push {r0}               @ Guarda los registros en la pila antes de usarlos
    mov r0, r2              @ Copia el contenido del registro r2 (2n+1) en r0 y r1 (uso posterior)
    
    cmp r0, #1              @ Compara el valor en r0 con 1
    beq factorial_casoBase  @ Si r0 es igual a 1, salta a la etiqueta factorial_casobase1

    cmp r0, #0              @ Compara el valor en r0 con 0
    beq factorial_casoBase @ Si r0 es igual a 0, salta a la etiqueta factorial_casoBase2

    vmov s2, r0             @ Cargar r0 en s2 
    vcvt.f32.s32 s2, s2     @ Convertir a float

factorial_loop:
    sub r0, r0, #1          @ Decrementa el contador en r0 (r0 = r0 - 1)

    vmov s1, r0             @ Cargar r2 en s2 (s0 = 2n+1)
    vcvt.f32.s32 s1, s1     @ Convertir a float

    vmul.f32 s0, s2, s1     @ Multiplica el total acumulado y el contador (s2 * s1), y guarda en s0
    vmov s2, s0             @ Copia el resultado de la multiplicación a s2

    cmp r0, #1              @ Compara el contador con 1
    beq factorial_exit      @ Si el resultado de la comparación es "igual" (r0 == 1), salta a factorial_exit
    
    b factorial_loop        @ Salta a factorial_loop para hacer otra iteración
                            @ Continúa hasta que el contador sea 0

factorial_casoBase:
    @ Caso base (factorial de 0 o factorial de 1)
    mov r0, #1
    vmov s0, r0             @ Cargar r2 en s2 (s0 = 2n+1)
    vcvt.f32.s32 s0, s0     @ Convertir a float

    b factorial_exit        @ Salta a factorial_exit

factorial_exit:
    pop {r0}                @ Restaura los registros desde la pila
    bx lr                   @ Devuelve el control a la función que llamó a factorial
