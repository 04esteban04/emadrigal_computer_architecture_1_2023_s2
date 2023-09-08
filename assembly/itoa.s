.macro pow base, exp
    mov r0, \base      @ Cargar la base
    mov r1, \exp       @ Cargar el exponente
    cmp r1, #0         @ Ver si el exponente es cero
    moveq r2, #1       @ Si es así, el resultado será 1
    beq 2f
    mov r2, r0         @ Copiar la base en el resultado (total)
    sub r1, #1         @ Restar uno al exponente porque copiamos la base
1:
    cmp r1, #0         @ Comprobar si necesitamos multiplicar de nuevo
    ble 2f             @ Salir si es igual o menor que 0
    mul r2, r0, r2     @ Multiplicar el total por la base y almacenar en el total
    sub r1, #1         @ Decrementar el exponente
    b 1b               @ Volver al punto 1 para más multiplicaciones
2:
    mov r0, r2         @ Mover el resultado a r0
.endm
.global itoa
itoa:
    push {r4-r9}            @ Guardar registros que se utilizarán
    mov r4, r1              @ Cargar la dirección de outstr
    mov r9, r1              @ Copiar a r9
    mov r5, r0              @ Cargar el número a procesar

    mov r7, #9              @ Potencia inicial de 10
    mov r8, #0              @ Inicializar el contador del bucle

    @ Encontrar la primera potencia de diez a usar
findstart:
    pow #10, r7             @ Obtener la potencia actual de diez
    mov r6, r0              @ Mover el resultado de la potencia a r6
    cmp r6, r5              @ Comparar 10^x con el número a imprimir
    ble finddigit           @ Si es menor que el número, ir a imprimir
    sub r7, #1              @ Si aún es mayor que el número, decrementa la potencia y prueba nuevamente
    b findstart
    @ Procesar el número e imprimir
finddigit:
    cmp r5, r6              @ Comparar el número restante con 10^x
    blt write               @ Si es menor, escribir el dígito
    add r8, r8, #1          @ Incrementar el contador
    sub r5, r5, r6          @ Restar 10^x del número restante y continuar
    b finddigit
write:
    add r8, #'0'            @ Sumar el contador a '0' en ASCII para obtener el número
    strb r8, [r4], #1       @ Almacenar en outstr e incrementar

    @ Preparar el siguiente bucle
    sub r7, #1              @ Restar uno al contador
    cmp r7, #0              @ Comparar contador con 0
    blt exit                @ Si el contador es <0, salir del bucle
    pow #10, r7             @ Obtener la siguiente potencia de diez
    mov r6, r0              @ Mover 10^x a r6
    mov r8, #0              @ Restablecer el contador del bucle
    b finddigit
exit:
    mov r8, #'\n'           @ Cargar salto de línea y nulo para la cadena de salida
    strb r8, [r4], #1       @ Almacenar en la salida. No es necesario incrementar
    mov r8, #0
    strb r8, [r4]

    mov r1, r9              @ Devolver la dirección en r1

    pop {r4-r9}             @ Restaurar registros
    bx lr                   @ Volver a la función llamadora
