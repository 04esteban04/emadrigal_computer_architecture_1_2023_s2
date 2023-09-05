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
file_path:  .asciz "INPUT.txt"     @ Ruta del archivo a abrir
fd:         .space 4           @ Descriptor de archivo
buffer:     .space 1           @ Buffer para leer un carácter
newline:    .asciz "\n"        @ Carácter de nueva línea
rowBuffer: .space 256         @ Búfer para almacenar una fila completa (ajusta el tamaño según tus necesidades)
bufferTOTALW: .space 1228800   @  1.17 MB Búfer para almacenar una fila completa (ajusta el tamaño según tus necesidades)
filas: .int 479
columnas: .int 639

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
    ble preCalculo

    @ Lee el carácter de buffer
    ldrb r3, [r1]

    @ Si el carácter leído es un salto de línea, imprime la fila completa
    cmp r3, #10
    beq preCarga

    strb r3, [r8, r10]
    add r10, r10, #4

    b loop

preCalculo:
    push {r0, r1, r2, r3, r4, r5, r6}
    ldr r2, =filas    @ Cargar la dirección de la etiqueta 'filas' en r0
    ldr r3, =columnas @ Cargar la dirección de la etiqueta 'columnas' en r1

    ldr r0, [r2]      @ Fila 480
    ldr r1, [r3]      @ Columna 640
    
    mov r2, #0         @ Fila actual (Y)
    mov r3, #0         @ Columna actual (X)

    b columna_loop

fila_loop:
    mov r2, #0         @ Fila actual (Y)

fila_inner_loop:
    mov r3, #0         @ Columna actual (X)

columna_loop:
    @ Calcular indice
    mul r5, r3, r0   @ Multiplica X por 480(ancho r9) y almacena en r5
    add r4, r5, r2   @ Suma el resultado de r5 con Y y almacena en r4
    mov r5, #4
    mul r4, r4, r5   @ Índice en espacio de memoria
    
    cmp r4, #1228800
    beq casoFinal

    ldr r10, [r11, r4] @ El valor de la lista (pixel a mover)

    b xy        @ X' esta en s6 y Y' está en s7

    vcvt.s32.f32 s6, s6
    vmov r4, s6

    vcvt.s32.f32 s7, s7
    vmov r5, s7

    cmp r4, #0              @ Comprobar si X' es negativo
    blt casoFinal

    cmp r5, #0              @ Comprobar si Y' es negativo
    blt casoFinal


    @ Calcular NUEVO indice
    mul r6, r4, r0   @ Multiplica X' por 480(ancho r9) y almacena en r5
    add r4, r6, r5   @ Suma el resultado de r6 con Y y almacena en r4
    mov r5, #4
    mul r4, r4, r5   @ Índice en espacio de memoria
    
    cmp r4, #1228800
    beq casoFinal

    mov r9, #0
    strb r10, [r11, r9] @ El valor de la lista (NUEVO INDICE)


    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt fila_inner_loop @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6}
    b preSend


casoFinal:
    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt fila_inner_loop @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6}
    b preSend






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
    
    ldr r11, =bufferTOTALW
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
