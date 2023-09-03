.macro      nullwrite       outstr
    @ Find length of string 
    ldr     r0, =\outstr        @ load outstring address
    mov     r1, r0              @ copy address for len calc later 
1:
    ldrb    r2, [r1]            @ load first char 
    cmp     r2, #0              @ check to see if we have a null char 
    beq     2f  
    add     r1, #1              @ Increment search address 
    b       1b                  @ go back to beginning of loop     
2:
    sub     r3, r1, r0          @ calculate string length 
    
    @ Setup write syscall 
    mov     r7, #4              @ 4 = write 
    mov     r0, #1              @ 1 = stdout 
    ldr     r1, =\outstr        @ outstr address 
    mov     r2, r3              @ load length 
    svc     0 
.endm 

@ target remote localhost:1233
.global _start

.section .data
file_path:  .asciz "in.txt"     @ Ruta del archivo a abrir
fd:         .space 4           @ Descriptor de archivo
buffer:     .space 1           @ Buffer para leer un carácter
newline:    .asciz "\n"        @ Carácter de nueva línea
rowBuffer: .space 256         @ Búfer para almacenar una fila completa (ajusta el tamaño según tus necesidades)
bufferTOTALW: .space 1228800   @  1.17 MB Búfer para almacenar una fila completa (ajusta el tamaño según tus necesidades)

.section .text
_start:

    @ Abre el archivo
    ldr r0, =file_path
    mov r1, #0      @ O_RDONLY (Modo de lectura)
    mov r7, #5      @ Código de llamada al sistema para abrir el archivo
    svc 0

    @ Verifica si hubo un error al abrir el archivo (r0 contiene el descriptor de archivo o el código de error)
    cmp r0, #-1
    beq error

    @ Almacena el descriptor de archivo en r9
    mov r9, r0

    @ Puntero de rowBuffer
    ldr r8, =rowBuffer
    ldr r11, =bufferTOTALW
    @ Contador temp de rowBuffer
    mov r10, #0
    @ Contador total de bufferTotalW
    mov r12, #0
loop:
    @ Lee un carácter del archivo
    mov r0, r9
    ldr r1, =buffer
    mov r2, #1        @ Lee un solo carácter a la vez
    mov r7, #3        @ Código de llamada al sistema para leer desde el archivo
    svc 0

    @ Verifica si se llegó al final del archivo (EOF)
    cmp r0, #0
    ble preSend

    @ Lee el carácter de buffer
    ldrb r3, [r1]

    @ Si el carácter leído es un salto de línea, imprime la fila completa
    cmp r3, #10
    beq preCarga

    strb r3, [r8, r10]
    add r10, r10, #4

    b loop
preCarga:
    @ Valores de rowBuffer
    ldr r7, [r8, #0]  
    ldr r6, [r8, #4]  
    ldr r5, [r8, #8]
    @ Valores de rowBuffer en decimal
    sub r7, r7, #48
    sub r6, r6, #48
    sub r5, r5, #48

    cmp r10, #4
    beq unDigito

    cmp r10, #8
    beq dosDigito

    cmp r10, #12
    beq tresDigito
unDigito:
    @ Guardamos el primero digito en el bufferTOTAL
    strb r7, [r11, r12]
    add r12, r12, #4
    b resetRow

dosDigito:
    mov r4, #10
    mul r7, r7, r4

    add r7, r7, r6
    @ Guardamos los dos digito en el bufferTOTAL
    strb r7, [r11, r12]
    add r12, r12, #4
    b resetRow
tresDigito:
    @ 301
    mov r4, #100
    mul r7, r7, r4
    
    mov r4, #10
    mul r6, r6, r4 
    
    add r7, r7, r6  
    add r7, r7, r5 
    @ Guardamos los tres digito en el bufferTOTAL
    strb r7, [r11, r12]
    add r12, r12, #4
    b resetRow
    
resetRow:
    @ Limpiamos los registros
    eor r7, r7
    eor r6, r6
    eor r5, r5
    eor r4, r4

    @ Reinicia el puntero de row_buffer al comienzo
    mov r10, #0
    ldr r8, =rowBuffer
    b loop

preSend:
    @ Contador total de bufferTotalW
    mov r12, #4
    ldr r11, =bufferTOTALW
    b send
send:
    @ Ver si llegamos al final de la lista
    cmp r12, #1228800
    beq end_program
    
    ldr r7, [r11] @El valor de la lista

    mov     r0, r7          @ move total to r4
    ldr     r1, =outstr     @ move buffer to r1 for write
    @ zero out output 
    mov     r2, #0          @ store null byte to use 
    str     r2, [r1]        @ bytes 0-3 
    str     r2, [r1, #4]    @ bytes 4-7 
    str     r2, [r1, #8]    @ bytes 8-11  
    bl      itoa            
    
    @ setup nullwrite 
    nullwrite   outstr
    
    add r12, r12, #4
    add r11, r11, #4
    b send

end_program:
    @ Cierra el archivo
    mov r0, r9
    mov r7, #6         @ Código de llamada al sistema para cerrar el archivo
    svc 0
    
    @ Salida del programa
    mov r0, #0         @ Código de retorno
    mov r7, #1         @ Código de llamada al sistema para salir
    svc 0


error:
    @ Manejo de errores (puedes personalizarlo según tus necesidades)
    mov r0, #1         @ Descriptor de archivo estándar (salida estándar)
    ldr r1, =newline
    mov r2, #1         @ Longitud del buffer (1 byte)
    mov r7, #4          @ Código de llamada al sistema para escribir en el archivo
    svc 0

    @ Salida del programa con código de error
    mov r0, #-1
    mov r7, #1
    svc 0


.data
outstr:     .fill 12        @ the max output size is 10 digits 
                            @ 11 for line ending 
