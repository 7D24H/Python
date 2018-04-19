;fib.asm

section .data
	promptString db "Please input x and y:",0ah ;提示输入
	promptLen equ $-promptString ;当前位置减字符串首地址即为字符长度

	wrongString db 0ah,"Please be sure y >= x,try again!",0ah	;当输入的y<x时的错误信息提示
	wrongLen equ $-wrongString

	newLine: db ' ',0Ah
	loopInitialABNum: dd 99	;给a,b初始化时用到的循环计数器，“高高低低原则”	;;db->dd 
	loopAddNum: dd 100		;数据相加的时候用到的循环计数器
	isOverflow: dd 0		;数据相加的时候用到的表示是否产生进位的变量，初始化为0，代表没有进位；若为1，则代表有进位
	
	pushTotalNum: dd 0		;输出时，记录把余数压栈的总次数	

	color: db 27,"[1;31m",27,"[1;32m",27,"[1;33m",27,"[1;34m",27,"[1;35m",27,"[1;36m",27,"[1;37m",27,"[1;30m"       ;红绿黄蓝,其中前面的1代表样式为（高亮）后半代表颜色
	currentColor: db 0				;当前选择颜色与color首地址的偏差值

	input dd 0	;就是一个用来存储每次输入的（十进制）数字的容器

	zero db '0',0xa
	one db '1',0xa	
	fibN dd 0	;计算到第几个fib值	
	
section .bss
	buff resb 1	;每次输入的字符地址;TODO 可以考虑resd统一
	varX resd 1	;用来放输入的x(已处理好的)
	varY resd 1	;用来放输入的y(已处理好的)
	
	a: resd 100				;在计算Fibonacci中用到的变量
	b: resd 100				;在计算Fibonacci中用到的变量
	tempB: resd 100	;做除法时每次用来存b区域的，因为会清零，但真正b区域里的不能被清零

	printPointer: resd 1	;输出时，当前应输出单元的地址

	aPointer resd 1	;fibA的地址
	bPointer resd 1	;fibB的地址
	tempBPointer resd 1;tempB的地址

	nextDivisionStartAddr resd 1;除十取余时每次除法的地址
		
section .text
	global main

main:	mov rax,0
	mov rbx,0
	mov rcx,0
	mov rdx,0

	mov eax,4	;Specify sys_write sys	;标准输出
	mov ebx,1	;Specify File Descriptor 1: Standard Output
	mov ecx,promptString	;Pass offset of the message
	mov edx,promptLen	;Pass the length of the message
	int 80h		;Make sys to output the text to stdout

	mov ebp,0	;currentColor要初始化，不知道为什么...
	mov [currentColor],ebp

read:	mov eax,3	;Specify sys_read 	;标准输入
	mov ebx,0	;Specify FILE Descriptor 0:Standard Input
	mov ecx,buff	;Pass address of the buffer to read to
	mov edx,1	;Tell sys_read to read one char from stdin
	int 80h		; sys_read

	mov cl,byte[buff]
	
	cmp cl,' '	;如果是空格 存储x
	je saveX
	cmp cl,0xa	;如果是回车 存储y
	je saveY

	;cmp cl,'0'
	;jl wrongPrint
	;cmp cl,'9'
	;jg wrongPrint
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
        mov eax,0
        mov [input],eax	;其实这里input的清零不是必需的

	mov eax,[varX]
	mov ebx,[varY]
	cmp eax,ebx
	jg wrongPrint

	jmp handleEachNum    ;这里开始进入fib计算
;-----------------------------------------------------------
wrongPrint:
	mov eax,4
	mov ebx,1
	mov ecx,wrongString
	mov edx,wrongLen
	int 80h

	jmp read	;main可以吗？？
;-----------------------------------------------------------
handleEachNum:

	;	push ebx		;由于dealWithEachArg是被其他方法调用的，ebx的值在其他方法中有用，所以返回的时候ebx不能被修改，因此先将ebx压栈
	;	push rbx
		mov eax, a		;aPointer中存储的值是a的起始地址
		mov [aPointer], eax
		mov ecx, b		;bPointer中存储的值是b的起始地址
		mov [bPointer], ecx
		mov ecx,tempB
		mov [tempBPointer],ecx

		;初始化a和b那部分内存的值，a，b初始值均为1，所以先把最低地址对应的内存单元的值初始化为1
		mov eax, 00h
		mov [a], eax
		mov ecx, 01h
		mov [b], ecx

		;a和b各自还剩下9个double word的内存单元尚未初始化，每个对应的值均为0，用循环去初始化，loopInitialABNum用作循环计数器，初始值为99
		mov eax, 99
		mov [loopInitialABNum], eax

		;循环
		loopInitialAB:
			mov eax, [loopInitialABNum]
			cmp eax, 0			;判断循环计数器loopInitialABNum的值是否为0
			je  endInitialAB	;如果为0，那么跳出循环，初始化结束

			mov eax, [aPointer]	;aPointer中存储的值是上一次a内存部分被初始化的单元（类型是double word）的起始地址（若是第一次，即是a的起始地址），把这个值给eax
			add eax, 4			;eax中的值加4，得到这次要初始化的单元（类型是double word）的起始地址
			mov [aPointer], eax	;把得到的新的单元起始地址再存到aPointer中

			mov edx, [aPointer]	;aPointer中存储的值是新的单元起始地址，把这个值给edx
			mov ecx, 00h		;ecx赋值为0
			mov [edx], ecx		;把ecx的值赋给edx中的值所指向的地址中，即把新的起始单元地址开始的4个Byte赋值为0

			mov eax, [bPointer]	;bPointer中存储的值是上一次b内存部分被初始化的单元（类型是double word）的起始地址（若是第一次，即是b的起始地址），把这个值给eax
			add eax, 4			;eax中的值加4，得到这次要初始化的单元（类型是double word）的起始地址
			mov [bPointer], eax	;把得到的新的单元起始地址再存到bPointer中

			mov edx, [bPointer]	;bPointer中存储的值是新的单元起始地址，把这个值给edx
			mov ecx, 00h		;ecx赋值为0
			mov [edx], ecx		;把ecx的值赋给edx中的值所指向的地址中，即把新的起始单元地址开始的4个Byte赋值0

			mov eax, [loopInitialABNum]	;把循环计数器loopInitialABNum的值减1，结果还要保存到loopInitialABNum中
			dec eax
			mov [loopInitialABNum], eax

			jmp loopInitialAB

		;初始化结束
		endInitialAB:
		;	pop ebx				;ebx在这里先出栈，但是如果下面的过程要改变ebx的值，依然需要压栈处理（如果现在不出栈，后期再出栈的话我怕会乱）
	;		pop rbx
			mov eax, a			;由于刚才循环的时候改变了aPointer的值，所以重新把a那部分内存的起始地址赋值给aPointer去存储
			mov [aPointer], eax
			mov eax, b			;由于刚才循环的时候改变了bPointer的值，所以重新把b那部分内存的起始地址赋值给bPointer去存储
			mov [bPointer], eax
			jmp countFibSpecial		;;;;;;;;;;;;;

;-------------------------------------------------------------------------------

countFibSpecial:	;这里是对特殊的fib值fib0 fib1进行判断是否可以直接输出
	mov eax,0
	mov ebx,[fibN]
	cmp ebx,eax
	je compareFib0	;如果正在fib(0),就去判断fib（0）要不要直接输出
	
	mov eax,1
	mov ebx,[fibN]
	cmp ebx,eax	;
	je compareFib1VarX

	jmp countFib	;这里要跳到正常的fib计算了 其实按道理都跳不回这里了

compareFib0:
	mov eax,[fibN]	;actually fibN=0
	mov ebx,[varX]
	cmp eax,ebx
	je outputFib0	;fibN=varX=0,因为varX最小不能小过0;TODO 错误提示？？
	mov eax,[fibN]	;否则fibN=fibN+1=1
	inc eax
	mov [fibN],eax
	jmp countFibSpecial	;跳回去看fib1是否要特殊输出

compareFib1VarX:
	mov eax,[fibN]	;actually fibN=1
	mov ebx,[varX]
	cmp eax,ebx	;fib1>=varX
	jge compareFib1VarY	;满足了大于下限，再去比是否fib1<=varY

	mov eax,[fibN]	;fib1<varX 不用输出了 但它是基石 所以肯定要跳回去算fib的
	inc eax		;fibN=fibN+1=2
	mov [fibN],eax
	jmp countFib	;以fibN=2的身份跳回正常的fib计算;TODO

compareFib1VarY:
	mov eax,[fibN]	;actually fibN=1
	mov ebx,[varY]
	cmp eax,ebx	;fib1<=varY
	jle outputFib1
	jmp exit	;fib1>varY,确实该退出了没问题,不用改，eg:0 0，也只有这一种情况会在这里就退出

outputFib0:
	mov eax,[fibN]	;保证以fibN=1的身份跳回
	inc eax
	mov [fibN],eax

	mov ebp, color			;改变当前输出颜色，先把颜色的起始地址给ebp
	add ebp, [currentColor]	;再加上当前颜色与起始地址的偏移，得到当前颜色的地址
	;add ebp, 0


	mov eax, 4
	mov ebx, 1
	mov ecx, ebp			
	mov edx, 7
	int 80h

	mov eax,4
	mov ebx,1
	mov ecx,zero
	mov edx,2
	int 80h		

	mov ebp, dword[currentColor]	;改变下一次输出颜色与起始地址的偏移值，先把当前输出颜色与起始地址的偏移值给ebp
	add ebp, 7						;偏移值加7，得到新的偏移值
	cmp ebp, 50						;检查偏移值是否越界
	jna NotBackZeroFib0					;如果没有越界，则不需要进行归0处理
	mov ebp, 0						;越界的话，新偏移值置0
	
NotBackZeroFib0:
	mov [currentColor], ebp			;把新得到的偏移值保存到currentColor中，
	jmp countFibSpecial	;跳回特殊值fib1的判断;	TODO

outputFib1:
	mov eax,[fibN]	;保证以fibN=2的身份跳回
        inc eax
        mov [fibN],eax

	mov ebp, color			;改变当前输出颜色，先把颜色的起始地址给ebp
	add ebp, [currentColor]	;再加上当前颜色与起始地址的偏移，得到当前颜色的地址

	mov eax, 4
	mov ebx, 1
	mov ecx, ebp			
	mov edx, 7
	int 80h
	
	mov eax,4
	mov ebx,1
	mov ecx,one
	mov edx,2
	int 80h
mov ebp, dword[currentColor]	;改变下一次输出颜色与起始地址的偏移值，先把当前输出颜色与起始地址的偏移值给ebp
	add ebp, 7						;偏移值加7，得到新的偏移值
	cmp ebp, 50						;检查偏移值是否越界
	jna NotBackZeroFib1					;如果没有越界，则不需要进行归0处理
	mov ebp, 0						;越界的话，新偏移值置0
	
NotBackZeroFib1:
	mov [currentColor], ebp			;把新得到的偏移值保存到currentColor中，

	jmp countFib	;这里应该是跳回正常的fib计算;TODO
;--------------------------------------------------------------------
countFib:
	mov eax, [aPointer]		;把a,b指针互换
	mov ebx, [bPointer]	
	mov [aPointer]	, ebx
	mov [bPointer]	, eax			

	;b+=a
	mov eax, [aPointer]		
	mov ebx, [bPointer]		
	call addData

	; addFibAB;fibN不管在不在范围内都先算出来
	jmp compareVarX
;--------------------------------------------------------
addData:
		mov ecx, 100				;每一次先把loopAddNum赋值为100
		mov [loopAddNum], ecx
		
		mov ecx, 00h				;每一次先把isOverflow赋值为0
		mov [isOverflow], ecx
		
	loopAdd:
		mov ecx, [loopAddNum]
		cmp ecx, 00h				;如果cl(loopAddNum)的值为0，跳出循环
		je endLoopAdd
		
		mov ecx, [eax]			;把以eax中的值为地址的那部分内容复制到ecx中去------源内存
		mov edx, [ebx]			;把以ebx中的值为地址的那部分内容复制到edx中去------目的内存
		
		add edx, ecx			;edx中的值加上ecx中的值，即目的内存的一个dw加上源内存对应的那个dw
		jc twoOperandsOverflow	;如果两个操作数相加就已经溢出的话，转去twoOperandsOverflow
		
		mov ecx, [isOverflow]	;如果两个操作数相加没有溢出，那么把上一次循环得到的进位给cl
		;movzx ecx, cl			;cl中的值做位扩展，现在ecx中的值为上一次循环得到的进位

		add edx, ecx			;edx中的值再加上传来的进位
		jc addCarryOverflow		;如果溢出，就去addCarryOverflow
		jmp addCarryNotOverflow	;如果仍然没有溢出，就去addCarryNotOverflow
	
	;加上上一轮进位后溢出的情况
	addCarryOverflow:
		
		mov ecx, 01h			;这一轮有进位，将isOverflow中的值改为1，保存
		mov [isOverflow], ecx
		jmp backLoop
	
	;加上上一轮进位后仍没有溢出的情况
	addCarryNotOverflow:
		
		mov ecx, 00h			;这一轮没有进位，将isOverflow中的值改为0，保存
		mov [isOverflow], ecx
		jmp backLoop
	
	;两个操作数相加就溢出的情况
	twoOperandsOverflow:
		
		mov ecx, [isOverflow]	;把上一次循环结束后得到的isOverflow的值给ecx
		add edx, ecx			;edx中的值再加上上一次循环传来的进位
		
		mov ecx, 01h			;这一轮没有进位，将isOverflow中的值改为1，保存
		mov [isOverflow], ecx
		jmp backLoop
		
	backLoop:
		mov [ebx], edx			;把加法得到的结果存到以ebx中的值为起始地址的内存中去
		
		add eax, 4				;eax中的值加4，得到下一个源内存单元（类型为double word）的起始地址（逐渐由低位到高位）
		add ebx, 4				;ebx中的值加4，得到下一个目的内存单元（类型为double word）的起始地址（逐渐由低位到高位）
		
		mov ecx, [loopAddNum]	;loopAddNum中的值减1，保存
		dec ecx
		mov [loopAddNum], ecx
		
		jmp loopAdd
		
	endLoopAdd:
		ret
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
	jle binaryToDecimal	;varX<=fibN<=varY 在范围内 输出！
	jmp exit	;fibN>varY 完成任务，正式退出！！（大部分都应该是在这里退的）

;--------------------------------

	;---------------------------------------------------------------------------------------------------------------
	;
	;把一个二进制的结果转化为十进制
	;就是这里……后来怎么改都跑不对……
	;
	



	binaryToDecimal:
	;	push ebx							;ebx中的值后期有用，先把ebx的值压栈
	;	push rbx
		mov ecx, [pushTotalNum]				;每一次转化为十进制，先把pushTotalNum的值初始化为0
		mov ecx, 0
		mov [pushTotalNum], ecx
		
		;把b区域的copy到tempB
		call copyFibBToTempB
		;返回以后tempB里就是和b里完全一样的东西了

		mov ebx, [tempBPointer]					;ebx中的值为b内存单元的起始地址
		add ebx, 399						;ebx中的值加上399，得到b内存单元最后一个byte的地址
		mov [nextDivisionStartAddr], ebx	;刚开始的时候，把进行除法的起始地址设为b内存单元最后一个byte的地址
		
	loopToDecimal:
		mov ebx, [nextDivisionStartAddr]	;ebx中的值是本次“字节循环除10”的起始地址
		call divisionByTen					;调用devisionByTen方法后，edx中的值是所得余数
			
		add edx, 30h						;将所得余数转换成对应的ascii形式
	;	push edx							;将余数对应的ascii形式压栈
		push rdx	
		mov ecx, [pushTotalNum]				;总的压栈次数加1
		inc ecx
		mov [pushTotalNum], ecx
	
		mov ebx, [nextDivisionStartAddr];ebx中的值是本次做完“字节循环除10”的起始地址
		
		mov al, byte[ebx]				;把起始地址指向的值（最高位）的byte形式给al
		movzx eax, al
		cmp eax, 0						;判断最高位的值是否为0
		je  changeNextDivisionStartAddr	
		
		jmp loopToDecimal			;如果最高位的值不为0的话，返回循环的过程
		
		;最高位的值为0的话，那么取下一个地址（低地址），若其中的值为0，继续循环，直至地址数到达b内存单元的开始或者地址内所含值不为0
		changeNextDivisionStartAddr:		
			
			loopDecreaseAddr:
				dec ebx
				mov ecx, [tempBPointer]		;ecx中的值是b内存单元的起始地址
				cmp ebx, ecx			;比较 下一个地址（低地址）和 b内存单元的起始地址 的大小
				jb	printResult	;如果 下一个地址（低地址）小于 b内存单元的起始地址 的话，直接结束
				mov al, byte[ebx]		;如果不等于的话，取出下一个地址中的值（byte类型），放入al中
				movzx eax, al			;al做位扩展，结果放入eax中
				cmp eax, 0				;看eax中的值是否为0
				je loopDecreaseAddr		;如果为0，那么继续取在下一位的地址，做循环判断
				mov [nextDivisionStartAddr], ebx	;如果不为0，那么把这个地址给nextDivisionStartAddr
				jmp loopToDecimal	;返回循环的过程
	

;-------------------------------------------
copyFibBToTempB:
		mov ebx,[bPointer]	;一开始ebx里存b区域的最高位地址
		add ebx,399
		mov ecx,[tempBPointer]	;ecx存tempB区域的最高位地址
		add ecx,399
		
	loopCopy:
		mov eax,[bPointer]	;eax在这里是临时寄存器，里面存了b区域的低位首地址
		cmp ebx,eax		;ebx比首地址还小了，说明拷贝结束
		jb endLoop
	
		mov eax,[ebx]		;否则把ebx所指区域的值复制给ecx所指区域
		mov [ecx],eax
		dec ebx			;ebx,ecx同时递减
		dec ecx	
		jmp loopCopy		;;;;;;;;;
	endLoop:
		ret
;-----------------------------------------------

		
	printResult:

		changeColor:			
			mov ebp, color			;改变当前输出颜色，先把颜色的起始地址给ebp
			add ebp, [currentColor]	;再加上当前颜色与起始地址的偏移，得到当前颜色的地址

			mov eax, 4
			mov ebx, 1
			mov ecx, ebp			
			mov edx, 7
			int 80h
			
		popStackLoop:
			
			mov edx, [pushTotalNum]	;把剩余的压栈次数给dex
			cmp edx, 00h			;比较剩余的压栈次数 和 0 的大小
			je  endPrint			;如果剩余压栈次数为0，结束本轮输出

			dec edx					;如果剩余压栈次数不为0，剩余压栈次数减一
			mov [pushTotalNum], edx	;把新得到的剩余压栈次数的值保存

		;	pop ecx					;出栈，把值先给ecx
			pop rcx
			mov [printPointer], ecx;再把该值给printByteAddr

			mov eax, 4				;输出该值
			mov ebx, 1
			mov ecx, printPointer
			mov edx, 1
			int 80h

			jmp popStackLoop		;继续进行出栈的循环

		endPrint:
			mov eax, 4				;本轮输出结束，输出换行
			mov ebx, 1
			mov ecx, newLine
			mov edx, 2
			int 80h
			

		changeCurrentColor:		
			mov ebp, dword[currentColor]	;改变下一次输出颜色与起始地址的偏移值，先把当前输出颜色与起始地址的偏移值给ebp
			add ebp, 7						;偏移值加7，得到新的偏移值
			cmp ebp, 50						;检查偏移值是否越界
			jna NotBackZero					;如果没有越界，则不需要进行归0处理
			mov ebp, 0						;越界的话，新偏移值置0
	
		NotBackZero:
			mov [currentColor], ebp			;把新得到的偏移值保存到currentColor中，
			
		;	pop ebx							
			pop rbx		
		;	ret								;返回调用它的handleEachNum主程序段

		endOutput:
			mov eax,[fibN]
			inc eax
			mov [fibN],eax
			jmp countFib	;输出一个继续跳回正常的算fib
	
	;---------------------------------------------------------------------------------------------------------------
	;对于一段给了起始地址的内存单元，对其中的每一个字节循环除10
	;
	divisionByTen:
	
		mov edx, 00h		;一开始的时候，余数初始化为0
		
		loopDivisionEachByte:
			
			mov eax, edx		;edx中的值是之前余数
			mov ecx, 256	
			mul ecx				;edx:eax中的值是余数乘上256的值
			mov ecx, eax		;把所得余数乘上256的值传给ecx
			
			mov al, byte[ebx]	;把当前地址指向的值的byte形式给al
			movzx eax, al		;al中的值做位扩展
			;mov eax, [ebx]	;把当前地址指向的值的byte形式给al;;;;;;;;;;;;;;;;;

			add eax, ecx		;上一字节所得余数乘上256与本字节的值相加
			mov ecx, 10
			div ecx				;余数在edx中，商在eax中
			
			mov byte[ebx], al	;把商的值保存到原来的内存单元中			;;;;!!!BUG!!!
			
			mov ecx, [tempBPointer]	;ecx中的值是b内存单元的起始地址
			cmp ebx, ecx		;ebx中的值是当前做完除法的字节的起始地址
			je endLoopDivisionEachByte	
			
			dec ebx						
			jmp loopDivisionEachByte
			
		endLoopDivisionEachByte:	
			ret

;-------------------------------



;-------------------------------------------------------------------------
;------------------------------------------------------
exit:   mov eax,1	;Specify Exit sys	;结束
        mov ebx,0	;a code of zero
        int 80h		;Make the sys to terminate the program
