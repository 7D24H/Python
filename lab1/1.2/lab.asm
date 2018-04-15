section .data
	promptString db "Please input x and y:",0ah ;提示输入
	promptLen: equ $-promptString ;当前位置减字符串首地址即为字符长度
	endl dd 0xa	;换行
	input dd 0	;就是一个用来存储每次输入的（十进制）数字的容器
	pushNum dd 0	;压栈次数
	loopInitial:dd 99	;初始化fibA fibB用的循环计数器
	zero db '0',0xa
	one db '1',0xa	
	fibN:dd 0	;计算到第几个fib值	
	
section .bss
	buff resb 1	;每次输入的字符地址
	varX resd 1	;用来放输入的x(已处理好的)
	varY resd 1	;用来放输入的y(已处理好的)
	
	fibA resd 100	;相当于fib中的f(n-2)
	fibB resd 100 	;相当于fib中的f(n-1)
	
	aPointer resd 1	;fibA的地址
	bPointer resd 1	;fibB的地址
	
	output resd 1	;输出地址的单元

section .text
	global main

main:	mov eax,4	;Specify sys_write syscall	;标准输出
	mov ebx,1	;Specify File Descriptor 1: Standard Output
	mov ecx,promptString	;Pass offset of the message
	mov edx,promptLen	;Pass the length of the message
	int 80h		;Make syscall to output the text to stdout

read:	mov eax,3	;Specify sys_read call	;标准输入
	mov ebx,0	;Specify FILE Descriptor 0:Standard Input
	mov ecx,buff	;Pass address of the buffer to read to
	mov edx,1	;Tell sys_read to read one char from stdin
	int 80h		;Call sys_read

;---------------------
	mov cl,byte[buff]
	cmp cl,' '	;如果是空格 存储x
	je saveX
	cmp cl,0xa	;如果是回车 存储y
	je saveY
;------------------------------
;这里的作用是将输入的ASCII码转成真正字面上的十进制
;方法是将之前存在input里的数乘十，再加上新输入的
	sub cx,0x30

	mov eax,[input]
	mov ebx,10
	mul ebx
	movzx ecx,cl	;符号扩展好和eax相加
	add eax,ecx
	mov [input],eax
	jmp read	;无条件跳转，继续读入下一个字符

;----------------------------------------------------------
saveX:	mov eax,[input]
	mov [varX],eax
	mov eax,0
	mov [input],eax	;input清零好准备存下一个十进制数
;	jmp pushX	;这里是测试stack的 已经成功
	jmp read	;继续读取Y

    ;----------------------------------------
	;用除十取余的方法输出
;pushX:	mov eax,[varX] ;被除数
 ;       mov ebx,10      ;除数
  ;      mov rdx,0       ;初始化余数
   ;     div ebx
    ;    add edx,0x30    ;余数以ASCII码输出
;	mov [varX],eax	;商存回去
 ;   	
;	push rdx	;把余数压栈
;	mov ecx,[pushNum]
;	inc ecx		;压栈次数要自增
;	mov [pushNum],ecx
;	
;	cmp eax,0	;被除数变为0说明已经除完了
;	je writeX	;就要出栈输出了
;	jmp pushX	;否则继续压栈

;writeX:	pop rcx
;	mov [output],ecx
;	mov ecx,[pushNum]
;	dec ecx
;	mov [pushNum],ecx

;	mov eax,4
;	mov ebx,1
;	mov ecx,output
;	mov edx,4
;	int 80h

;	mov ecx,[pushNum]
;	cmp ecx,0
;	je read
;	jmp writeX
    ;-----------------------------------------
	;这里只是为了测试x有没有存进varX，所以输出varX中数对应的ASCII（可能会溢出），
	;其实这里并不用输出的
;	mov eax,4
;	mov ebx,1
;	mov ecx,varX
;	mov edx,1
;	int 80h
;
;	mov eax,4	;换行
;	mov ebx,1
;	mov ecx,endl
;	mov edx,1
;	int 80h
    ;-----------------------------------------------
;	jmp read	;这句是需要的！跳回去读y
;----------------------------------------------------------- 

saveY:  mov eax,[input]
        mov [varY],eax
        mov eax,0
        mov [input],eax
       ;-------------------
	;待删
     ;   mov eax,4       ;输出从键盘输入的东西
    ;    mov ebx,1
   ;     mov ecx,varY
  ;      mov edx,1
 ;       int 80h
;
;	mov eax,4       ;换行
    ;    mov ebx,1
   ;     mov ecx,endl
  ;      mov edx,1
 ;       int 80h

       ;------------------
	 jmp startFib 	;要改的 这里应该进入正式的fib计算

;-----------------------------------------------------------

startFib:
	mov eax,fibA
	mov [aPointer],eax
	mov ebx,fibB
	mov [bPointer],ebx

	mov eax,0
	mov [fibA],eax	;初始化fib(0)=0
	mov ebx,0
	mov [fibB],ebx	;初始化fib(1)=1

initialAB:
	mov eax,[loopInitial]
	cmp eax,0
	je endIni
	
	mov eax,[aPointer]	;继续初始化fibA
	add eax,4		;往前走 继续初始化为0
	mov [aPointer],eax
	mov ecx,[aPointer]	;ecx里放的是要初始为0的地址单元	
	mov edx,0
	mov [ecx],edx

	mov ebx,[bPointer]	;继续初始化fibB
        add ebx,4               ;往前走 继续初始化为0
        mov [bPointer],ebx
        mov ecx,[bPointer]      ;ecx里放的是要初始为0的地址单元 
        mov edx,0
        mov [ecx],edx

	mov eax,[loopInitial]
	dec eax			;初始化循环计数器减一
	mov [loopInitial],eax

	jmp initialAB		;继续初始化

endIni:	mov eax,fibA		;恢复fibA fibB的起始地址到aPointer bPointer中
	mov [aPointer],eax
	mov ebx,fibB
	mov [bPointer],ebx

countFib:
	mov eax,0
	mov ebx,[fibN]
	cmp ebx,eax
	je compareFib0	;如果正在fib(0),就去判断fib（0）要不要直接输出
	
	mov eax,1
	mov ebx,[fibN]
	cmp ebx,eax	;eax里有fibN值 和
	je compareFib1

	jmp exit
	
compareFib0:
	mov eax,[fibN]
	mov ebx,[varX]
	cmp eax,ebx
	je outputFib0
	mov eax,[fibN]
	inc eax
	mov [fibN],eax
	jmp countFib

compareFib1:
	mov eax,[fibN]
	mov ebx,[varX]
	cmp eax,ebx	;fib1>=varX
	jge compareVarY
	
	mov eax,[fibN]
	inc eax
	mov [fibN],eax
	
	jmp countFib
compareVarY:
	mov eax,[fibN]
	mov ebx,[varY]
	cmp eax,ebx	;fib1<=varY
	jle outputFib1
	jmp exit

outputFib0:
	mov eax,[fibN]
	inc eax
	mov [fibN],eax

	mov eax,4
	mov ebx,1
	mov ecx,zero
	mov edx,2
	int 80h
	jmp countFib

outputFib1:
	mov eax,[fibN]
        inc eax
        mov [fibN],eax
	
	mov eax,4
	mov ebx,1
	mov ecx,one
	mov edx,2
	int 80h
	jmp countFib

exit:   mov eax,1	;Specify Exit syscall	;结束
        mov ebx,0	;Return a code of zero
        int 80h		;Make the syscall to terminate the program

