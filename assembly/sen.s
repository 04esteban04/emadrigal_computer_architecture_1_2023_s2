.section .text
.global sen_start       @ Define la función global "sen"

sen_start:
    push {r0, r1, r2, r3, r4, r5}
    mov r0, #-1     @ Cargar en r0 el valor de n (Contador cantidad de terminos de la serie)
    mov r1, #2      @ Cargar la constante 2
    mov r2, #0      @ Se guarda el resultado de (2n+1) = (r0*r1 + 1)
    
    mov r3, #-1     @ Termino alternado
    mov r4, #-1

    mov r5, #0      @ Inicialización de resultado
    vmov s5, r5             @ Cargar r5 en s5
    vcvt.f32.s32 s5, s5     @ Convertir a float

    @mov r6, #10
    @vmov s8, r6     @ Valor de X o Y actual
    @vcvt.f32.s32 s8, s8     @ Convertir a float

sen_loop:
    add r0, r0, #1  @ Se aumenta n en 1
    mul r2, r0, r1  @ Se multiplica n por 2
    add r2, r2, #1  @ Se obtiene (2*n + 1)

    bl factorial    @ Se obtiene el factorial de (2n+1) en s0

    bl potencia     @ Se obtiene el valor de (base ^ (2n+1)) en s1       

    vdiv.f32 s2, s1, s0     @ numerador/denominador (se guarda en s2)

    mul r5, r3, r4          @ Generar termino alternado
    mov r3, r5

    vmov s3, r3             @ Guardar termino alternado en s3
    vcvt.f32.s32 s3, s3     @ Convertir a float

    vmul.f32 s4, s3, s2     @ Se multiplica resultado de division por termino alternado

    vadd.f32 s5, s5, s4     @ Guardar resultado de termino de la serie

    cmp r0, #16             @ Terminar el ciclo (terminos de la serie)
    beq sen_exit
    
    b sen_loop              @ Repetir el ciclo  

sen_exit:
    pop {r0, r1, r2, r3, r4, r5}
    
    @ Devuelve el control a la función que llamó a sen
    cmp r6, #1
    beq return_newx

    cmp r6, #0
    beq return_newy

return_newx:
    ldr pc, =0x80c8   @ Carga la dirección en el Program Counter (PC)

return_newy:
    ldr pc, =0x8104   @ Carga la dirección en el Program Counter (PC)
