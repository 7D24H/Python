#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define FAT_START  0x0200	
#define ROOT_START 0x2600	
#define DATA_START 0x4200	

#define UNVALID 0						
#define VALID_FILE 1					
#define DIRECTORY 2

#define TRUE 1
#define FALSE 0

typedef struct{
	char    extra32[32];		//因为是64位的 所以前面多了32字节
	char 	DIR_Filename[8];	//文件名8字节
	char 	DIR_Extension[3];	//扩展名3字节
	char 	DIR_Attr[1];		//文件属性
	char 	DIR_Reserved[10];	//保留位
	char 	DIR_WrtTime[2];				
	char 	DIR_WrtDate[2];				
	char 	DIR_FstClus[2];		//此条目对应的开始簇号
	char 	DIR_FileSize[4];	//文件大小
}Dir;



char* start="> ";
char* point=".";
char* enter="\n";
char* space=" ";
char* unvalid="Unvalid order!";
char* unknown="Can not find the path!";

void asmPrint(char* c,int len);
void lsAll(FILE* fat12);
void showNames(FILE* file, char* path, int offset, Dir* dir);
void printValidFile(Dir* dir);
int isEmpty(Dir* dir);
int isValidPath(char* path);
int getAttribute(Dir* dir);


int main(){
	FILE* fat12;
	fat12 = fopen("a.img","rb");

	char order[10]; //ls cat count exit
	char path[20];	//具体路径
	
	while(1){
		asmPrint(start,strlen(start));
		scanf("%s",order);

		//TODO 输出所有的目录和文件
		if(strcmp(order,"ls")==0){
			char c;
			if((c=getchar())=='\n'){
				//asmPrint(unvalid,strlen(unvalid));
				lsAll(fat12);
				
			}
			else{
				scanf("%s",path);
				if(isValidPath(path)){
					//TODO
					asmPrint(path,strlen(path));
				}
			}
			
		}

		//TODO 详细文件内容输出
		else if(strcmp(order,"cat")==0){
			scanf("%s",path);
			asmPrint(path,strlen(path));
		}


		//TODO 输出文件个数
		else if(strcmp(order,"count")==0){
			scanf("%s",path);
			asmPrint(path,strlen(path));
		}

		//DONE 退出
		else if(strcmp(order,"exit")==0){
			break;
		}

		//DONE 无效指令
		else{
			asmPrint(unvalid,strlen(unvalid));
		}

		asmPrint("\n",1);
		
	}
	
}

void lsAll(FILE* fat12){
	
	//if(fat12 == NULL){	
		//TODO printWarning(openFileFailedWarning);	
	//	exit(1);								
	//}
	
	Dir* dir1 = (Dir*)malloc(sizeof(Dir));
	memset(dir1, 0, sizeof(Dir));	
	showNames(fat12, "", ROOT_START, dir1);
	showNames(fat12, "", ROOT_START+0x40, dir1);
	showNames(fat12, "", ROOT_START+0x80, dir1);
	showNames(fat12, "", ROOT_START+0xC0, dir1);

	//fclose(fat12);				
	free(dir1);								
	//free(subDir1);

}

void showNames(FILE* file, char* currentPath, int offset, Dir* dir){					
	
	long currentPosition = ftell(file);         			
	
	fseek(file, offset, SEEK_SET);     			
	memset(dir, 0, sizeof(Dir));											
	fread(dir, sizeof(Dir), 1, file);			
		
	printValidFile( dir);
	asmPrint(space,1);
											
}

void printValidFile(Dir* dir){
								
	for(int i=0; i<8; i++){		
		if(dir->DIR_Filename[i] != ' '){
			asmPrint(&dir->DIR_Filename[i], 1);	
		}
	}		
	
	if(getAttribute(dir)==VALID_FILE){
		asmPrint(point,1);
	}
						
	for(int i=0; i<3; i++){		
		if(dir->DIR_Extension[i] != ' '){
			asmPrint(&dir->DIR_Extension[i], 1);
		}
	}
}

int getAttribute(Dir* dir){
	
	//先判断有效性
	//FAT默认用‘ ’填充文件名和扩展名，而文件名的第一个字符绝不可能为‘ ’
	
	char c = dir->DIR_Filename[0];

	if(c < '0' || c > 'z')	
		return UNVALID;				

	for(int i=1; i<8; i++){		
		c = dir->DIR_Filename[i];		
		if(c < ' ' || c > '}'){			
			return UNVALID;			
		}
	}
	
	for(int j=0; j<3; j++){			
		c = dir->DIR_Extension[j];	
		if(c < ' ' || c > '}'){		
			return UNVALID;	
		}
	}
	
	//如果运行到了这里，则证明文件有效，那么判断它的属性
	
	c = dir->DIR_Attr[0];
	
	if((c & 0x10) == 0x10){
		return DIRECTORY;	
	}
	else{
		return VALID_FILE;	
	}
}


int isValidPath(char* path){
	if(((char)path[0])!='/'){
		asmPrint(unknown,strlen(unknown));
		return FALSE;
	}else{
		return TRUE;
	}

}

int isEmpty(Dir* dir){
	int i = 0;
	for(i=0; i<32; i++){			
		if(((char*)dir)[i] > 0){		
			return FALSE;						
		}
	}
	return TRUE;
}

