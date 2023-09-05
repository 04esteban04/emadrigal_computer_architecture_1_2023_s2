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
	arm-none-eabi-as factorial.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o factorial.o
	arm-none-eabi-as potencia.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o potencia.o
	arm-none-eabi-as sen.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o sen.o
	arm-none-eabi-as newx.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o newx.o
	arm-none-eabi-as newy.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o newy.o
	arm-none-eabi-as xy.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o xy.o
	arm-none-eabi-as main.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o main.o
	arm-none-eabi-as itoa.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o itoa.o
	arm-none-eabi-ld main.o itoa.o factorial.o potencia.o sen.o newx.o newy.o xy.o -o main
#	./main
	
aa:
	./main
cc:
	qemu-arm -singlestep -g 1233 main

od: 
	arm-linux-gnueabi-objdump -d main