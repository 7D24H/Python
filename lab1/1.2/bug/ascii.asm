section .data
	promptString db "Please input x and y:",0ah ;提示输入
	promptLen equ $-promptString ;当前位置减字符串首地址即为字符长度
	
	
	endl dd 0xa	;换行
	input dd 0	;就是一个用来存储每次输入的（十进制）数字的容器
	pushNum dd 0	;压栈次数

	loopInitial dd 99	;初始化fibA fibB用的循环计数器
	loopAdd dd 100	;fibA fibB逐个单元相加时用到的计数器
	carryBit dd 0	;加法时用来存上一轮相加的进位的

	zero db '0',0xa
	one db '1',0xa	
	fibN dd 2	;计算到第几个fib值
	sum dd 0,0xa	
	
section .bss

	
	buff resb 1	;每次输入的字符地址;TODO 可以考虑resd统一
	varX resd 1	;用来放输入的x(已处理好的)
	varY resd 1	;用来放输入的y(已处理好的)
	
	fibA resd 1	;相当于fib中的f(n-2)
	fibB resd 1 	;相当于fib中的f(n-1)
	
	aPointer resd 1	;fibA的地址
	bPointer resd 1	;fibB的地址
	dividePointer resd 1;除十取余时每次除法的地址
		
	output resd 1	;输出地址的单元

section .text
	global main

main:	mov rax,0
	mov rbx,0
	mov rcx,0
	mov rdx,0

	mov eax,4	;Specify sys_write syscall	;标准输出
	mov ebx,1	;Specify File Descriptor 1: Standard Output
	mov ecx,promptString	;Pass offset of the message
	mov edx,promptLen	;Pass the length of the message
	int 80h		;Make syscall to output the text to stdout

read:	mov eax,3	;Specify sys_read call	;标准输入
	mov ebx,0	;Specify FILE Descriptor 0:Standard Input
	mov ecx,buff	;Pass address of the buffer to read to
	mov edx,1	;Tell sys_read to read one char from stdin
	int 80h		;Call sys_read

	mov cl,byte[buff]
	cmp cl,' '	;如果是空格 存储x
	je saveX
	cmp cl,0xa	;如果是回车 存储y
	je saveY
;------------------------------
;这里的作用是将输入的ASCII码转成真正字面上的十进制
;方法是将之前存在input里的数乘十，再加上新输入的

	sub cx,0x30	;输入的ASCII字符转成真正的数字
	mov eax,[input]	;之前input里累积的乘十加上新输入的
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
	mov [input],eax	;input清零好准备存下一个十进制的数
	jmp read	;继续读取

saveY:  mov eax,[input]
        mov [varY],eax

	jmp startFib    ;这里开始进入正式的fib计算
;-----------------------------------------------------------
startFib:
	mov eax,fibA
	mov [aPointer],eax
	mov ebx,fibB
	mov [bPointer],ebx

	mov eax,0
	mov [fibA],eax	;初始化fib(0)=0
	mov ebx,1
	mov [fibB],ebx	;初始化fib(1)=1

;-------------------------------------------------------------------------------


;--------------------------------------------------------------------
countFib:
	mov eax,[aPointer]	;a b指针互换 整个过程其实是fibA fibB区域的内容一直在交替表示ab 指针跟上去而已
	mov ebx,[bPointer]	;eg:假设[aPointer]=12340000,[bPointer]=56780000
	mov [aPointer],ebx
	mov [bPointer],eax      ;eg：现在就是[aPointer]=56780000,[bPointer]=12340000,bPointer指向的区域马上要用来存放相加结果了

	mov eax,[aPointer]	;call的时候会用到 不要改了
	mov ebx,[bPointer]

	mov ecx,[eax]	;在call addFibAB之前就存好的  eax=[aPointer]=56780000 ; ebx=[bPointer]=12340000
	mov edx,[ebx]	;ecx=a区域首地址的内容 edx=b区域首地址的内容

	add edx,ecx
	mov [ebx],edx	;把加法结果存入现在bPointer所指向区域 内

	mov [sum],edx
	mov eax,[sum]
	add eax,0x30
	mov [sum],eax

	jmp compareVarX
;------------------------------------------------------------

compareVarX:
	mov eax,[fibN]
	mov ebx,[varX]
	cmp eax,ebx
	jge compareVarY	;fibN>=varX,继续和varY比，看是否要输出

	mov eax,[fibN]	;fibN<varX,不要气馁！是后面计算的基石，自增返回
	inc eax
	mov [fibN],eax
	jmp countFib

compareVarY:
	mov eax,[fibN]
	mov ebx,[varY]
	cmp eax,ebx
	jle outputFibB	;varX<=fibN<=varY 在范围内 输出！
	jmp exit	;fibN>varY 完成任务，正式退出！！（大部分都应该是在这里退的）

;--------------------------------

outputFibB:

	;一系列操作把fibB的值从二进制变成十进制并以ASCII码的形式压栈存起来
	mov edx,0
	mov [pushNum],edx	;初始化压栈次数
	mov ebx,[bPointer]	;ebx中放的是fibB区域的首地址
	mov eax,[ebx]

loopDecimal:	
	

	mov edx,0	;余数初始化为0

	mov ecx,10	;ecx=10	
	div ecx		;eax/ecx=eax......edx

	add edx,0x30	;喜提余数，以ASCII码形式压栈
	push rdx	;因为是64位的，所以edx->rdx压栈
	mov ecx,[pushNum]
	inc ecx		;压栈次数++，出栈要用的
	mov [pushNum],ecx
	cmp eax,0
	je printFibB
	jmp loopDecimal	;否则继续除这个byte
	
;-------------------------------
printFibB:
popStack:
	mov edx,[pushNum]
	cmp edx,0
	je endPrint

	dec edx
	mov [pushNum],edx
	
	pop rcx
	mov [output],rcx

	mov eax,4
	mov ebx,1
	mov ecx,output
	mov edx,1
	int 80h

	jmp popStack

endPrint:
	mov eax,4
	mov ebx,1
	mov ecx,endl
	mov edx,2
	int 80h

endOutputFibB:
	mov eax,[fibN]
	inc eax
	mov [fibN],eax
	jmp countFib	;输出一个继续跳回正常的算fib

;-------------------------------------------------------------------------
;------------------------------------------------------
exit:   mov eax,1	;Specify Exit syscall	;结束
        mov ebx,0	;Return a code of zero
        int 80h		;Make the syscall to terminate the program

