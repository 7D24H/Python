section .data
	promptString db "Please input x and y:",0ah ;提示输入
	promptLen equ $-promptString ;当前位置减字符串首地址即为字符长度
	endl db 0xa	;换行
	input dd 0	;就是一个用来存储每次输入的（十进制）数字的容器
	pushNum dd 0	;压栈次数

	loopInitial dd 99	;初始化fibA fibB用的循环计数器
	loopAdd dd 100	;fibA fibB逐个单元相加时用到的计数器

	carryBit dd 0	;加法时用来存上一轮相加的进位的

	

	zero db '0',0xa
	one db '1',0xa	
	fibN dd 0	;计算到第几个fib值	

	color: db 27,"[1;31m",27,"[1;32m",27,"[1;33m",27,"[1;34m",27,"[1;35m",27,"[1;36m",27,"[1;37m",27,"[1;30m"       ;红绿黄蓝,其中前面的1代表样式为（高亮）后半代表颜色
	currentColor: db 0				;当前选择颜色与color首地址的偏差值
	
section .bss
	buff resb 1	;每次输入的字符地址;TODO 可以考虑resd统一
	varX resd 1	;用来放输入的x(已处理好的)
	varY resd 1	;用来放输入的y(已处理好的)
	
	fibA resd 100	;相当于fib中的f(n-2)
	fibB resd 100 	;相当于fib中的f(n-1)
	tempB: resd 100	;做除法时每次用来存b区域的，因为会清零，但真正b区域里的不能被清零

	aPointer resd 1	;fibA的地址
	bPointer resd 1	;fibB的地址
	tempBPointer resd 1;tempB的地址

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

	mov ebp,0	;currentColor要初始化，不知道为什么...
	mov [currentColor],ebp

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
        mov eax,0
        mov [input],eax	;其实这里input的清零不是必需的

	jmp startFib    ;这里开始进入正式的fib计算
;-----------------------------------------------------------
startFib:
	mov eax,fibA
	mov [aPointer],eax
	mov ebx,fibB
	mov [bPointer],ebx
	mov ecx,tempB
	mov [tempBPointer],ecx

	mov eax,0
	mov [fibA],eax	;初始化fib(0)=0
	mov ebx,1
	mov [fibB],ebx	;初始化fib(1)=1

	mov eax,99
        mov [loopInitial],eax	;初始化循环计数器 因为可能已经被改写了

initialAB:
	mov eax,[loopInitial]
	cmp eax,0
	je exitInitial
	
	mov eax,[aPointer]	;继续初始化fibA
	add eax,4		;往前走 继续初始化为0
	mov [aPointer],eax
	
	mov edx,[aPointer]	;ecx里放的是要初始为0的地址单元	
	mov ecx,0
	mov [edx],ecx

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

exitInitial:
	mov eax,fibA		;恢复fibA fibB的起始地址到aPointer bPointer中
	mov [aPointer],eax
	mov ebx,fibB
	mov [bPointer],ebx

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

	mov eax,4
	mov ebx,1
	mov ecx,zero
	mov edx,2
	int 80h
	jmp countFibSpecial	;跳回特殊值fib1的判断;	TODO

outputFib1:
	mov eax,[fibN]	;保证以fibN=2的身份跳回
        inc eax
        mov [fibN],eax
	
	mov eax,4
	mov ebx,1
	mov ecx,one
	mov edx,2
	int 80h
	jmp countFib	;这里应该是跳回正常的fib计算;TODO
;--------------------------------------------------------------------
countFib:
	mov eax,[aPointer]	;a b指针互换 整个过程其实是fibA fibB区域的内容一直在交替表示ab 指针跟上去而已
	mov ebx,[bPointer]	;eg:假设[aPointer]=12340000,[bPointer]=56780000
	mov [aPointer],ebx
	mov [bPointer],eax      ;eg：现在就是[aPointer]=56780000,[bPointer]=12340000,bPointer指向的区域马上要用来存放相加结果了

	mov eax,[aPointer]	;call的时候会用到 不要改了
	mov ebx,[bPointer]

	call addFibAB

	;call addFibAB;fibN不管在不在范围内都先算出来
	jmp compareVarX
;--------------------------------------------------------
addFibAB:
	mov ecx,100
	mov [loopAdd],ecx

	mov ecx,0
	mov [carryBit],ecx

loopAddAB:
	mov ecx,[loopAdd]
	cmp ecx,0
	je endLoopAdd
	
	mov ecx,[eax]	;在call addFibAB之前就存好的  eax=[aPointer]=56780000 ; ebx=[bPointer]=12340000
	mov edx,[ebx]	;ecx=a区域首地址的内容 edx=b区域首地址的内容

	add edx,ecx
	jc fibABOverflow	;jc=jump if carry,有进位就跳转
	
	mov ecx,[carryBit]	;单纯相加时没有溢出，安心加上进位位
	
	add edx,ecx
	jc fibABCarryBitOverflow;加上进位位突然溢出！
	jmp noOverflowAtAll	;good good怎样都不溢出～

fibABOverflow:
	mov ecx,[carryBit]
	add edx,ecx	;因为它一下就溢出了，还没来得及加上上次的进位位，现在加上！这次加是不会再次溢出的 eg:1111+1111=(1)1110
	
	mov ecx,1
	mov [carryBit],ecx	;为下一轮加法准备好进位位1
	jmp moveBackLoop

fibABCarryBitOverflow:
	mov ecx,1	;下一轮进位位=1
	mov [carryBit],ecx
	jmp moveBackLoop

noOverflowAtAll:
	mov ecx,0	;下一轮进位位=0
	mov [carryBit],ecx
	jmp moveBackLoop

moveBackLoop:
	mov [ebx],edx	;把加法结果存入现在bPointer所指向区域 内
		
	add eax,4	;通通向后，得到下一个要相加的单元
	add ebx,4	

	mov ecx,[loopAdd]
	dec ecx
	mov [loopAdd],ecx

	jmp loopAddAB
endLoopAdd:
	ret	;回到countFib啦！
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
	jle prepareFibB	;varX<=fibN<=varY 在范围内 输出！
	jmp exit	;fibN>varY 完成任务，正式退出！！（大部分都应该是在这里退的）

;--------------------------------
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
prepareFibB:

	;一系列操作把fibB的值从二进制变成十进制并以ASCII码的形式压栈存起来
	mov eax,[pushNum]	
	mov eax,0
	mov [pushNum],eax	;初始化压栈次数
	
	;把b区域的copy到tempB
	call copyFibBToTempB
	;返回以后tempB里就是和b里完全一样的东西了

	mov ebx, [tempBPointer]					;ebx中的值为b内存单元的起始地址

	add ebx,399		;退到最高位的byte，因为fibB是resd 100,d=double word=4byte
	mov [dividePointer],ebx	;进行除法的地址单元，一开始是最后一个byte

loopDecimal:
	mov ebx,[dividePointer];
	call dividedByTen

	add edx,0x30	;喜提余数，以ASCII码形式压栈
	push rdx	;因为是64位的，所以edx->rdx压栈
	mov ecx,[pushNum]
	inc ecx		;压栈次数++，出栈要用的
	mov [pushNum],ecx

	mov ebx,[dividePointer]	;call divideByTen的时候ebx被改写到和bPointer里的一样了（这个正是返回条件），所以一定要重新装进去

	mov al,byte[ebx]	;[ebx]的值在loopDivideByte每个byte被除一次为得到余数的时候都被存过
	movzx eax,al	
	cmp eax,0
	je decDividePointer;如果当前byte全部被除没了（因为得到余数的过程也是位数下降的过程），就可以继续往下个byte了
	jmp backLoopToDecimal	;否则继续除这个byte

decDividePointer:
	dec ebx
	mov ecx,[tempBPointer]
	cmp ebx,ecx
	jb printFibB	;ebx已经减到比fibB区域首地址都要小了，说明已经该压的栈全压了，打印！

	;;;否则当然是要减少dividePointer的值啊！
	mov al,byte[ebx]
	movzx eax,al
	cmp eax,0
	je decDividePointer	;还要看这个byte是不是本来就是0,是的话就不用理他了，因为这个字节十怎么除都不会留余数给下一个字节用的

	mov [dividePointer],ebx
	jmp backLoopToDecimal	;否则带着减了一的ebx回去继续战斗！

backLoopToDecimal:
	mov ecx,[tempBPointer]
	cmp ebx,ecx
	jb endLoopToDecimal
	jmp loopDecimal

endLoopToDecimal:
	jmp printFibB	
;------------------------
dividedByTen:		;ebx里有dividePointer里的值 所以不要动ebx
	mov edx,0	;余数初始化为0

loopDivideByte:
	mov eax,edx	;edx是上一轮除剩下的余数
	mov ecx,256
	mul ecx		;eax里现在放着左移了8位的余数，因为它相对于这轮要除的byte来说就是比他们要大256倍，得供起来，最多挤到16位，不会溢出的放心
	mov ecx,eax	;;;

	mov al,byte[ebx]	;当前要除的byte里的值
	movzx eax,al
	add eax,ecx	;eax里放了加了上一轮余数左移8位和现在byte相加的值（类比加法还得拖家带口个进位位）
	mov ecx,10	;ecx=10	
	div ecx		;eax/ecx=eax......edx

	mov byte[ebx],al	;把商存进原来的内存单元中;;;;;;;;;;;;;;;

	mov ecx,[tempBPointer]
	cmp ebx,ecx
	je endLoopDivideByte
	dec ebx		;这里是为了从高到低走一遍只为了最低位的那个余数，故每个字节除一次就可以了
	jmp loopDivideByte;还没到最低位，故继续往下走

endLoopDivideByte:
	ret		;成功取到最低位的余数并存在edx中，回loopDecimal交差！
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

