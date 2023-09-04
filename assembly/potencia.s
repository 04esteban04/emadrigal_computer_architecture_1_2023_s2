.section .text     
.global potencia           @ Define la función global "potencia"

potencia:
    push {r0, r1}       @ Guarda los registros en la pila antes de usarlos
    mov r1, r2              @ Copia el valor de la potencia actual (2n+1)
    
    cmp r1, #0              @ Compara el valor en r5 con 0 (potencia 0)
    beq potencia_casoBase0  @ Si r5 es igual a 0, salta a la etiqueta potencia_casoBase0

    cmp r1, #1              @ Compara el valor en r5 con 1 (potencia 1)
    beq potencia_casoBase1  @ Si r5 es igual a 1, salta a la etiqueta potencia_casoBase1

    vmov s1, s8             @ Cargar s8 en s0 (base)
    vmov s2, s8             @ Cargar s8 en s1 (base)


potencia_loop:
    sub r1, r1, #1          @ Decrementa el contador en r1 (r1 = r1 - 1)

    vmul.f32 s3, s1, s2     @ Multiplica el total acumulado y el contador (s2 * s1), y guarda en s0
    vmov s1, s3             @ Copia el resultado de la multiplicación a s2

    cmp r1, #1              @ Compara el contador con 1
    beq potencia_exit       @ Si el resultado de la comparación es "igual" (r1 == 1), salta a potencia_exit
    
    b potencia_loop         @ Salta a potencia_loop para hacer otra iteración
                            @ Continúa hasta que el contador sea 0

potencia_casoBase0:
    @ Caso base (potencia de 0)
    mov r0, #1              @ Establece r0 en 1
    vmov s1, r0             @ Cargar r0 en s1 (s1 = x^(2n+1))
    vcvt.f32.s32 s1, s1     @ Convertir a float

    b potencia_exit         @ Salta a potencia_exit

potencia_casoBase1:
    @ Caso base (potencia de 1)
    vmov s1, s8             @ Cargar r0 en s1 (s1 = x^(2n+1))

    b potencia_exit         @ Salta a potencia_exit

potencia_exit:
    pop {r0, r1}            @ Restaura los registros desde la pila
    bx lr                   @ Devuelve el control a la función que llamó a potencia
