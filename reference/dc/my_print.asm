;数据区
section .data
  colorchange: 		db 1bh,'[49;34m' ;改变输出的颜色
  colorchangelen:	equ $-colorchange 
  colorreset:  		db 1bh,'[0m'   ;恢复默认设置
  colorresetlen:  		equ $-colorreset 

;代码区
section .text
global my_print
global change_color
global reset_color

my_print:
	mov edx,dword[esp+8] ;第一个参数是输出的长度
	mov ecx,dword[esp+4] ;从右往左第二个参数是要输出的字符
	mov ebx,1
	mov eax,4
	int 80h
	ret

change_color:
	mov eax,4
	mov ebx,1
	mov ecx,colorchange
	mov edx,colorchangelen
	int 80h
	ret

reset_color:
	mov eax,4
	mov ebx,1
	mov ecx,colorreset
	mov edx,colorresetlen
	int 80h
	ret