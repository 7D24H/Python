global asmPrint

section .text
	;asmPrint(char* ch,int len)
	asmPrint:
		mov	edx,[esp+8]						
		mov	ecx,[esp+4]						
		mov	ebx,1
		mov	eax,4 
		int	80h
		ret


