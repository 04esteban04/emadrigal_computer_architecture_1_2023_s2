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
	arm-none-eabi-as main.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o main.o
	arm-none-eabi-as itoa.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o itoa.o
	arm-none-eabi-ld main.o itoa.o -o main
	./main
	
aa:
	./main
cc:
	qemu-arm -singlestep -g 1233 main

od: 
	arm-linux-gnueabi-objdump -d main