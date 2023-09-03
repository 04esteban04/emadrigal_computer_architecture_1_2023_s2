all:
	arm-none-eabi-as test.s -g -o test.o
	arm-none-eabi-ld test.o -o test
	./test
c:
	arm-none-eabi-as test.s -g -o test.o
	arm-none-eabi-ld test.o -o test
	qemu-arm -singlestep -g 1233 test
d:
	arm-none-eabi-gdb

a:
	arm-none-eabi-as main.s -g -o main.o
	arm-none-eabi-as itoa.s -g -o itoa.o
	arm-none-eabi-ld main.o itoa.o -o main
aa:
	./main
cc:
	qemu-arm -singlestep -g 1233 main