@ target remote localhost:1233
.section .data
buffer:
    .space 307200    @ Reservar 307200 bytes de memoria para el buffer (300 KB)

.section .text
.global _start
_start:
    @ Poner la dirección base del buffer en un registro
    ldr r0, =buffer
    @ Contador
    mov r1, #0
loop:
    @ Verifica si el contador es mayor que 10
    cmp r1, #307200
    bgt end
    
    @ Colocar '0' en la posición r1 del buffer
    add r2, r0, r1  @ Dirección de la posición r1
    mov r3, #'0'     @ Valor '0'
    strb r3, [r2]

    @ Incrementa el contador
    add r1, r1, #1
    b loop
end:
    @ Colocar 'Z' en la posición 40 del buffer
    add r2, r0, #40  @ Dirección de la posición 40
    mov r3, #'Z'     @ Valor 'Z'
    strb r3, [r2]  
    
    @ Colocar '52' en la posición 40 del buffer
    add r2, r0, #4  @ Dirección de la posición 40
    mov r3, #'!'     @ Valor 'Z'
    strb r3, [r2]  

    @ Tu código aquí (finalización del programa)    
    @ Preparar para imprimir el contenido del buffer
    mov r0, #1          @ Descriptor de archivo 1 (salida estándar)
    ldr r1, =buffer     @ Dirección del búfer
    mov r2, #307200     @ Longitud del búfer (307200 bytes)
    mov r7, #4          @ Código de la syscall de escritura
    swi 0               @ Hacer la syscall

    @ Terminar el programa
    mov r7, #1     @ Código de la syscall de salida
    swi 0          @ Hacer la syscall

