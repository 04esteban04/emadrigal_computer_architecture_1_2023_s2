.section .text     
.global factorial           @ Define la función global "factorial"

factorial:
    push {r3, r4}           @ Guarda los registros r3 y r4 en la pila antes de usarlos
    mov r2, r1              @ Copia el contenido del registro r1 en r2 y r3 (uso posterior)
    mov r3, r1
    
    cmp r2, #1              @ Compara el valor en r2 con 1
    beq factorial_exit      @ Si r1 es igual a 1, salta a la etiqueta factorial_exit

    cmp r2, #0              @ Compara el valor en r2 con 0
    beq factorial_baseCase  @ Si r2 es igual a 0, salta a la etiqueta factorial_baseCase

factorial_loop:
    sub r3, r3, #1          @ Decrementa el contador en r3 (r3 = r3 - 1)
    mul r4, r2, r3          @ Multiplica el total acumulado y el contador (r2 * r3), y guarda en r4
    mov r2, r4              @ Copia el resultado de la multiplicación a r2
    
    cmp r3, #1              @ Compara el contador con 1
    beq factorial_exit      @ Si el resultado de la comparación es "igual" (r3 == 1), salta a factorial_exit
    
    b factorial_loop        @ Salta a factorial_loop para hacer otra iteración
                            @ Continúa hasta que el contador sea 0

factorial_baseCase:
    @ Caso base (factorial de 0)
    mov r2, #1              @ Establece r2 en 1
    b factorial_exit        @ Salta a factorial_exit

factorial_exit:
    pop {r3, r4}            @ Restaura los registros r3 y r4 desde la pila
    bx lr                   @ Devuelve el control a la función que llamó a factorial
