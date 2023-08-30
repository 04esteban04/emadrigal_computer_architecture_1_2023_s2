@ target remote localhost:1233
.global _start
.equ O_RDONLY, 0x0
 .data
fname:      .asciz      "INPUT.txt"
outbuf:     .fill       12      @ 12 = 10 digits + \n + \0
readbuf:    .fill       64      @ read buffer 64 bytes

.section .bss
filedescriptor: .space 4    @ File descriptor

.section .text

_start:
    mov     r4, #0          @ Initialize total to 0
    ldr     r8, =outbuf     @ Load the address of outbuf into r8
    mov     r10, #0         @ Initialize last number to 0

    @ setup open
    mov     r7, #5          @ 5 = open
    ldr     r0, =fname      @ Load the address of fname into r0 (filename)
    mov     r1, #O_RDONLY   @ Set r1 to O_RDONLY (read-only mode)
    mov     r2, #0          @ Set r2 to 0 (no additional flags)
    svc     0                @ Invoke a system call to open the file
    mov     r5, r0          @ Move the file descriptor to r5 for later use

    @ setup read
    mov     r7, #3          @ 3 = read
    mov     r0, r5          @ File descriptor in r0
    ldr     r1, =readbuf    @ Buffer address in r1
    mov     r2, #64         @ Number of bytes to read in r2 (64 bytes in this case)
    svc     0                @ Invoke a system call to read from the file

    @ check if read was successful (r0 contains the number of bytes read)
    cmp     r0, #0
    blt     error            @ If r0 is negative, there was an error

    @ r0 now contains the number of bytes read
    @ You can process the data in readbuf here

exit:
    @ setup exit
    mov     r7, #1          @ 1 = exit
    mov     r0, #0          @ 0 = no error
    svc     0

error:
    @ Handle the error here, e.g., by printing an error message and exiting
    @ setup exit
    mov     r7, #1          @ 1 = exit
    mov     r0, #0          @ 0 = no error
    svc     0
