section .data
	pathColor db 27, '[1;34m', 0 
	pathColorLen equ $ - pathColor
	fileColor db 27, '[1;33m', 0 
	fileColorLen equ $ - fileColor
	warnColor db 27, '[1;31m', 0 
	warnColorLen equ $ - warnColor
	terminalColor db 27, '[0m', 0 
	terminalColorLen equ $ - terminalColor


global asmPrint
global prepareOutputDirectory
global prepareOutputFile
global prepareWarning
global prepareTerminal

section .text
	;asmPrint(char* ch,int len)
	asmPrint:
		mov	edx,[esp+8]						
		mov	ecx,[esp+4]						
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


