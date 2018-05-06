section .data
	pathColor db 27, '[1;34m', 0 
	pathColorLen equ $ - pathColor
	fileColor db 27, '[1;33m', 0 
	fileColorLen equ $ - fileColor
	warnColor db 27, '[1;31m', 0 
	warnColorLen equ $ - warnColor
	terminalColor db 27, '[0m', 0 
	terminalColorLen equ $ - terminalColor

section .text
	global my_print
	global prepareOutputDirectory
	global prepareOutputFile
	global prepareWarning
	global prepareTerminal

	;my_print(char* c, int length);
	;利用栈传递参数
	
	my_print:
		mov	edx,[esp+8]						;[esp+8] = Q - 04h, 得到length
		mov	ecx,[esp+4]						;[esp+4] = Q - 08h, 得到c
		mov	ebx,1
		mov	eax,4 
		int	80h
		ret

	prepareOutputDirectory:
		mov eax, 4
		mov ebx, 1
		mov ecx, pathColor
		mov edx, pathColorLen
		int 80h
		ret

	prepareOutputFile:
		mov eax, 4
		mov ebx, 1
		mov ecx, fileColor
		mov edx, fileColorLen
		int 80h
		ret
	
	prepareWarning:
		mov eax, 4
		mov ebx, 1
		mov ecx, warnColor
		mov edx, warnColorLen
		int 80h
		ret
		
	prepareTerminal:
		mov eax, 4
		mov ebx, 1
		mov ecx, terminalColor
		mov edx, terminalColorLen
		int 80h
		ret