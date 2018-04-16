;这个是Fibonacci进阶版
;检查的时候发现自己把fib1=1,fib2=1了，结果和助教小姐姐的预先设定完全不一样，后来发现以后，加了一行代码就好了，完美通关~~~~
;循环前先加1吧

section .data
	promptStr: db '请输入一串数字（用空格隔开） : '	
	promptStrLen: equ $-promptStr
	errorStr: db '错误：输入了0或空格数过多', 0Ah
	errorStrLen: equ $-errorStr
	newLine: db ' ',0Ah

	eachNum: dd 0			;每一个输入的数字都被存放在这里，将其初始化为0

	loopInitialABNum: db 99	;给a,b初始化时用到的循环计数器，“高高低低原则”

	loopMoveNum: db 100		;数据移动的时候用到的循环计数器
	
	loopAddNum: db 100		;数据相加的时候用到的循环计数器
	isOverflow: db 0		;数据相加的时候用到的表示是否产生进位的变量，初始化为0，代表没有进位；若为1，则代表有进位
	
	nextDivisionStartAddr:	dd 0;下一次除法的起始地址
	
	pushTotalNum: dd 0		;输出时，记录把余数压栈的总次数
	

	color: db 27,"[1;31m",27,"[1;32m",27,"[1;33m",27,"[1;34m"       ;红绿黄蓝,其中前面的1代表样式为（高亮）后半代表颜色
	currentColor: db 0				;当前选择颜色与color首地址的偏差值

section .bss
	inputPointer: resb 1	;输入字符串的当前地址指针
	a: resd 100				;在计算Fibonacci中用到的变量
	b: resd 100				;在计算Fibonacci中用到的变量

	aPointer: resd 1		;变量的当前地址指针
	bPointer: resd 1		;变量的当前地址指针
	printPointer: resd 1	;输出时，当前应输出单元的地址


section .text
	global main

main:

	;---------------------------------------------------------------------------------------------------------------
	;提示用户输入的提示语句
	;
	showPrompt:
		mov eax, 4
		mov ebx, 1
		mov ecx, promptStr
		mov edx, promptStrLen
		int 80h

	;---------------------------------------------------------------------------------------------------------------
	;一个字一个字的读入，如果没有遇到空格，就将eachNum里原有的数字*10加新的数字在个位
	;如果遇到空格，就代表一个数字输入完毕，可以计算其fib值
	;如果遇到0Ah，则代表输入结束
	;
	readNext:

		mov eax, 3
		mov ebx, 0
		mov ecx, inputPointer
		mov edx, 1
		int 80h						;读入的字存放在inputPointer里
		
		mov cl, byte[inputPointer]	

		cmp cl, 0Ah					;检查输入字符串是否已经结束	
		je endAllNum				;程序结束

		cmp cl, ' '					;如果遇到空格，则说明一个输入的数字结束
		je endOneNum				;一个数字结束

		sub cl, 30h					;若还没有结束，把输入的字符转换成对应的数字
		mov eax, [eachNum]

		mov edx, 10
		mul edx						;eax * 10 的结果存放在edx:eax中
		movzx ecx, cl				;cl进行位扩展，便于与eax相加
		add eax, ecx				;把新读入的数字加到eachNum的个位
		mov [eachNum], eax			;保存eachNum的值

		jmp readNext				;继续读下一位

		endOneNum:
			call handleEachNum		;处理已有数字
			mov edx, 0
			mov [eachNum], edx		;将eachNum中存的值清零
			jmp readNext

		endAllNum:
			call handleEachNum		;处理已有数字
			jmp  exit	

	;---------------------------------------------------------------------------------------------------------------
	;对每一个eachNum，计算其fib值，并打印出来
	;
	handleEachNum:

	;	push ebx		;由于dealWithEachArg是被其他方法调用的，ebx的值在其他方法中有用，所以返回的时候ebx不能被修改，因此先将ebx压栈
		push rbx
		mov eax, a		;aPointer中存储的值是a的起始地址
		mov [aPointer], eax
		mov ecx, b		;bPointer中存储的值是b的起始地址
		mov [bPointer], ecx

		;初始化a和b那部分内存的值，a，b初始值均为1，所以先把最低地址对应的内存单元的值初始化为1
		mov eax, 00h
		mov [a], eax
		mov ecx, 01h
		mov [b], ecx

		;a和b各自还剩下9个double word的内存单元尚未初始化，每个对应的值均为0，用循环去初始化，loopInitialABNum用作循环计数器，初始值为99
		mov al, 99
		mov [loopInitialABNum], al

		;循环
		loopInitialAB:
			mov al, [loopInitialABNum]
			cmp al, 0			;判断循环计数器loopInitialABNum的值是否为0
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

			mov al, [loopInitialABNum]	;把循环计数器loopInitialABNum的值减1，结果还要保存到loopInitialABNum中
			dec al
			mov [loopInitialABNum], al

			jmp loopInitialAB

		;初始化结束
		endInitialAB:
		;	pop ebx				;ebx在这里先出栈，但是如果下面的过程要改变ebx的值，依然需要压栈处理（如果现在不出栈，后期再出栈的话我怕会乱）
			pop rbx
			mov eax, a			;由于刚才循环的时候改变了aPointer的值，所以重新把a那部分内存的起始地址赋值给aPointer去存储
			mov [aPointer], eax
			mov eax, b			;由于刚才循环的时候改变了bPointer的值，所以重新把b那部分内存的起始地址赋值给bPointer去存储
			mov [bPointer], eax

		computeFib:
		;	push ebx				;ebx中的值有用，后面的过程会修改ebx中的值，因此先将ebx压栈
			push rbx	
			mov edx, [eachNum]		;把eachNum的值赋给edx
			inc edx 				;就是这步，使得fib0=1,fib1=1

		;循环，用来计算fib(n)
		loopFib:
			cmp edx, 02h			;如果当前edx中的值小于等于2，此时b那部分内存单元中的值已经是最终结果，即fib(n)，跳转到endLoopFib
			jbe  endLoopFib

			;如果eachNum当前的值大于2，计算fib(n)
		;	push edx				;edx中的值有用，由于addData方法会改变edx中的值，所以先压栈
			push rdx

			mov eax, [aPointer]		;把a,b指针互换
			mov ebx, [bPointer]	
			mov [aPointer]	, ebx
			mov [bPointer]	, eax			

			;b+=a
			mov eax, [aPointer]		
			mov ebx, [bPointer]		
			call addData

		;	pop edx					;edx中的值出栈		
			pop rdx
			dec edx
			jmp loopFib
		
		;如果有0或者过多的空格输入，提示错误信息，直接结束
		errorOutput:
			mov eax, 4
			mov ebx, 1
			mov ecx, errorStr
			mov edx, errorStrLen
			int 80h

			jmp exit	
			
		endLoopFib:
		;	pop ebx			;ebx中的值出栈	
			pop rbx
			
	;---------------------------------------------------------------------------------------------------------------
	;
	;把一个二进制的结果转化为十进制
	;就是这里……后来怎么改都跑不对……
	;
	binaryToDecimal:
	;	push ebx							;ebx中的值后期有用，先把ebx的值压栈
		push rbx
		mov ecx, [pushTotalNum]				;每一次转化为十进制，先把pushTotalNum的值初始化为0
		mov ecx, 0
		mov [pushTotalNum], ecx
		
		mov ebx, [bPointer]					;ebx中的值为b内存单元的起始地址
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
		
		jmp backLoopToDecimal			;如果最高位的值不为0的话，返回循环的过程
		
		;最高位的值为0的话，那么取下一个地址（低地址），若其中的值为0，继续循环，直至地址数到达b内存单元的开始或者地址内所含值不为0
		changeNextDivisionStartAddr:		
			
			loopDecreaseAddr:
				dec ebx
				mov ecx, [bPointer]		;ecx中的值是b内存单元的起始地址
				cmp ebx, ecx			;比较 下一个地址（低地址）和 b内存单元的起始地址 的大小
				jb	endLoopToDecimal	;如果 下一个地址（低地址）小于 b内存单元的起始地址 的话，直接结束
				mov al, byte[ebx]		;如果不等于的话，取出下一个地址中的值（byte类型），放入al中
				movzx eax, al			;al做位扩展，结果放入eax中
				cmp eax, 0				;看eax中的值是否为0
				je loopDecreaseAddr		;如果为0，那么继续取在下一位的地址，做循环判断
				mov [nextDivisionStartAddr], ebx	;如果不为0，那么把这个地址给nextDivisionStartAddr
				jmp backLoopToDecimal	;返回循环的过程
			
		backLoopToDecimal:
			mov ecx, [bPointer]			;ecx中的值是b内存单元的起始地址
			cmp ebx, ecx				;比较下一次“字节循环除10”的起始地址 和 b内存单元的起始地址 的大小
			jb	endLoopToDecimal		;如果下一次“字节循环除10”的起始地址 小于 b内存单元的起始地址 的话，结束
			jmp loopToDecimal			;反之，继续循环
	
	endLoopToDecimal:
		jmp printResult			;转换结束后，输出结果
		
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
			cmp ebp, 22						;检查偏移值是否越界
			jna NotBackZero					;如果没有越界，则不需要进行归0处理
			mov ebp, 0						;越界的话，新偏移值置0
	
		NotBackZero:
			mov [currentColor], ebp			;把新得到的偏移值保存到currentColor中，
			
		;	pop ebx							
			pop rbx		
			ret								;返回调用它的主程序段
	
	
	
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
			add eax, ecx		;上一字节所得余数乘上256与本字节的值相加
			mov ecx, 10
			div ecx				;余数在edx中，商在eax中
			
			mov byte[ebx], al	;把商的值保存到原来的内存单元中
			
			mov ecx, [bPointer]	;ecx中的值是b内存单元的起始地址
			cmp ebx, ecx		;ebx中的值是当前做完除法的字节的起始地址
			je endLoopDivisionEachByte	
			
			dec ebx						
			jmp loopDivisionEachByte
			
		endLoopDivisionEachByte:	
			ret

	;---------------------------------------------------------------------------------------------------------------
	;自己实现了加法器……突然想起了计组TAT
	;eax中是源操作数,ebx中是目的操作数
	;
	addData:
		mov cl, 100				;每一次先把loopAddNum赋值为100
		mov [loopAddNum], cl
		
		mov ch, 00h				;每一次先把isOverflow赋值为0
		mov [isOverflow], ch
		
	loopAdd:
		mov cl, [loopAddNum]
		cmp cl, 00h				;如果cl(loopAddNum)的值为0，跳出循环
		je endLoopAdd
		
		mov ecx, [eax]			;把以eax中的值为地址的那部分内容复制到ecx中去------源内存
		mov edx, [ebx]			;把以ebx中的值为地址的那部分内容复制到edx中去------目的内存
		
		add edx, ecx			;edx中的值加上ecx中的值，即目的内存的一个dw加上源内存对应的那个dw
		jc twoOperandsOverflow	;如果两个操作数相加就已经溢出的话，转去twoOperandsOverflow
		
		mov cl, [isOverflow]	;如果两个操作数相加没有溢出，那么把上一次循环得到的进位给cl
		movzx ecx, cl			;cl中的值做位扩展，现在ecx中的值为上一次循环得到的进位

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
		
		mov cl, [loopAddNum]	;loopAddNum中的值减1，保存
		dec cl
		mov [loopAddNum], cl
		
		jmp loopAdd
		
	endLoopAdd:
		ret

	;---------------------------------------------------------------------------------------------------------------
	;结束，撒花~
	;
	exit:
		mov eax, 1
		mov ebx, 0
		int 80h
