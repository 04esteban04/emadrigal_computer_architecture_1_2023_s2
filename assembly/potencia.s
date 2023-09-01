.section .text     
.global potencia           @ Define la función global "potencia"

potencia:
    push {r2, r5}           @ Guarda los registros en la pila antes de usarlos
    mov r2, r3              @ Copia el contenido del registro r3 en r2 (base)
    mov r5, r1              @ Copia el valor de r1 a r5 (potencia actual)
    
    cmp r5, #0              @ Compara el valor en r5 con 0 (potencia 0)
    beq potencia_casoBase0  @ Si r5 es igual a 0, salta a la etiqueta potencia_casoBase0

    cmp r5, #1              @ Compara el valor en r5 con 1 (potencia 1)
    beq potencia_casoBase1  @ Si r5 es igual a 1, salta a la etiqueta potencia_casoBase1

potencia_loop:
    sub r5, r5, #1          @ Decrementa el contador en r5 (r5 = r5 - 1)
    mul r4, r2, r3          @ Multiplica el total acumulado y el contador (r2 * r2), y guarda en r4
    mov r2, r4

    cmp r5, #1              @ Compara el contador con 1
    beq potencia_exit       @ Si el resultado de la comparación es "igual" (r5 == 1), salta a potencia_exit
    
    b potencia_loop         @ Salta a potencia_loop para hacer otra iteración
                            @ Continúa hasta que el contador sea 0

potencia_casoBase0:
    @ Caso base (potencia de 0)
    mov r4, #1              @ Establece r4 en 1
    b potencia_exit         @ Salta a potencia_exit

potencia_casoBase1:
    @ Caso base (potencia de 1)
    mov r4, r2              @ Establece r4 en r2 (base)
    b potencia_exit         @ Salta a potencia_exit

potencia_exit:
    pop {r2, r5}            @ Restaura los registros desde la pila
    bx lr                   @ Devuelve el control a la función que llamó a potencia
