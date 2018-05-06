#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FAT_START  0x0200				//FAT12中，FAT区从第1扇区开始，1*512 = 512 = 0x0200
#define ROOT_START 0x2600				//FAT12中，根目录区从第19扇区开始，19*512 = 9728 = 0x2600
#define DATA_START 0x4200				//FAT12中，数据区从第33扇区开始，33*512 = 16896 = 0x4200

#define FALSE 0							
#define TRUE 1							

#define UNVALID 0						
#define VALID_FILE 1					
#define DIRECTORY 2						

#define SHOW_MODE 3						//代表显示模式
#define COUNT_MODE 4					//代表统计模式
#define SEARCH_MODE 5					//代表搜寻模式

typedef struct
{
	char 	DIR_Filename[8];			//文件名8字节
	char 	DIR_Extension[3];			//扩展名3字节
	char 	DIR_Attr[1];				//文件属性
	char 	DIR_Reserved[10];			//保留位
	char 	DIR_WrtTime[2];				//最后一次写入时间
	char 	DIR_WrtDate[2];				//最后一次写入日期
	char 	DIR_FstClus[2];				//此条目对应的开始簇号
	char 	DIR_FileSize[4];			//文件大小
} Dir;


void showAllContents();
void showContents(FILE* file, char* path, int offset, Dir* dir, Dir* subDir);
int showContentsInADirectory(FILE* file, char* directoryPath, Dir* directoryDir, Dir* subDir);
void showFileContent(FILE* file, Dir* fileDir);

void searchContentsInSpecificPath();
void searchContents(char* specificPath, int searchType, int depthInSpecificPath, int depthToSearch, FILE* file, char* currentPath, int offset, Dir* dir, Dir* subDir);

void readSubDir(FILE* file, int subOffset, Dir* subDir);
void pathPlus(char* path, char* oldPathDIR_Filename, char* oldPathDIR_Extension);
int isEmpty(Dir* dir);
int getAttribute(Dir* dir);
int getClus(FILE* file, int n);

void printDirectoryPath(char* path);
void printValidFile(char* path, Dir* dir);

void my_print(char* c, int length);
void printStr(char* inputTip);
void printNum(int num);
void printWarning(char* warning);	//为了变色，单独提出来做一个方法

void prepareOutputDirectory();
void prepareOutputFile();
void prepareWarning();
void prepareTerminal();

FILE* file;

int mode;						//用来表示当前的模式：显示模式/统计模式/搜寻模式
int haveFound;					//用来表示在统计模式/搜寻模式下，是否已经找到目标文件或者文件夹
	
int countResultLevels[50];		//用来保存统计数组中每一个统计结果的深度
int countResultNums[100];		//用来保存统计数组中每一个统计结果的子文件个数、子文件夹个数
char countResultNames[600];		//用来保存统计数组中每一个统计结果的文件夹名字
int countResultLength;			//用来保存统计数组中统计结果的长度

char* floppyName = "a.img\0";

char* openFileFailedWarning = "Warning : Open file failed\n\0";
char* mallocMemoryFailedWarning = "Warning : Malloc memory failed\n\0";
char* fileNameOverflowWarning = "Wrong : File name length overflow!\n\0";
char* emptyFileWarning = "Warning : It is an Empty File\n\0";
char* unknownFileWarning = "unknown path\n\0";
char* notADirectory = "Not a directory!\n\0";

char* inputTip = "Please input the file path('Q' to quit):\0";
char* quitTip = "Quit\n\0";

char* countResultFilePart = " files, \0";
char* countResultDirectoryPart = " directories \n\0";

int continueProgram = TRUE;


int main(){
	
	//功能点1
	showAllContents();

	//功能点2,3
	while(continueProgram){
		searchContentsInSpecificPath();
	}
	
	return 0;
}

/*----------------------------------------------------------------------------------------------------------------------------
读取文件，显示里面存放的内容，完成后关闭该文件
*/
void showAllContents(){
	
	file = fopen(floppyName, "r");
	
	if(file == NULL){	
		printWarning(openFileFailedWarning);	
		exit(1);								
	}
	
	Dir* dir1 = (Dir*)malloc(sizeof(Dir));
	memset(dir1, 0, sizeof(Dir));			
	Dir* subDir1 = (Dir*)malloc(sizeof(Dir));	
	memset(subDir1, 0, sizeof(Dir));	
	
	mode = SHOW_MODE;
	showContents(file, "", ROOT_START, dir1, subDir1);	

	fclose(file);				
	free(dir1);								
	free(subDir1);		
}



/*----------------------------------------------------------------------------------------------------------------------------
按照不同类型(VALID_FILE/DIRECTORY)显示一个文件中的全部内容
*/
void showContents(FILE* file, char* currentPath, int offset, Dir* dir, Dir* subDir){					
	
	long currentPosition = ftell(file);         			
	
	do{	
		fseek(file, offset, SEEK_SET);     			
		memset(dir, 0, sizeof(Dir));											
		fread(dir, sizeof(Dir), 1, file);			

		int attribute = getAttribute(dir);										
		
		//如果目录条目的属性是文件夹，将这个文件夹加到的路径末尾，调用showContentsInADirectory方法，继续显示这个文件夹中的内容
		if(attribute == DIRECTORY){
			
			char* thisDirectoryPath = (char*)malloc(strlen(currentPath) + 0x0B);
				
			if(thisDirectoryPath == NULL){							
				printWarning(mallocMemoryFailedWarning);	
				exit(1);										
			}
			
			memset(thisDirectoryPath, 0, strlen(thisDirectoryPath));		
			memcpy(thisDirectoryPath, currentPath, strlen(currentPath));	
			pathPlus(thisDirectoryPath, dir->DIR_Filename, dir->DIR_Extension);
			
			showContentsInADirectory(file, thisDirectoryPath, dir, subDir);	
		}
		//如果目录条目的属性是有效文件，打印文件的路径，文件名，扩展名，结束递归
		else if(attribute == VALID_FILE){		
			printValidFile(currentPath, dir);	
		}
		offset += 32;			
	}while(!isEmpty(dir));
	
	fseek(file, currentPosition, SEEK_SET);										
}


/*----------------------------------------------------------------------------------------------------------------------------
显示一个文件夹中的全部内容
*/
int showContentsInADirectory(FILE* file, char* directoryPath, Dir* directoryDir, Dir* subDir){
	
	int fst_Clus = directoryDir->DIR_FstClus[0] + directoryDir->DIR_FstClus[1] * 0x10;
	fst_Clus = fst_Clus & 0x000000ff;		
	int subStartAddr = (fst_Clus - 2) * 0x200 + DATA_START;	

	int subDirectoryCount = 0;		
	int subFileCount = 0;															
	
	//一个扇区有512个字节，一共16个条目
	for(int i=0; i<16; i++){
		readSubDir(file, subStartAddr + 32*i, subDir);	
		//如果读到的子目录条目为空，说明这个条目和它后面的条目均未被使用							
		if(isEmpty(subDir) == TRUE){												
			break;																	
		}
		else{																		
			
			int attribute = getAttribute(subDir);									
			
			//如果子目录条目的属性是文件夹，将这个文件夹加到的路径末尾，递归继续显示这个文件夹中的内容
			if(attribute == DIRECTORY){	
				char* subDirectoryPath = (char*)malloc(strlen(directoryPath) + 0x0B); 
				
				if(subDirectoryPath == NULL){			
					printWarning(mallocMemoryFailedWarning);						
					exit(1);														
				}
				
				//如果分配内存成功，将directoryPath中的内容复制到subDirectoryPath的前面，将11字节的文件夹的文件名和扩展名追加入subDirectoryPath
				memset(subDirectoryPath, 0, strlen(directoryPath)+0x0B);			
				memcpy(subDirectoryPath, directoryPath, strlen(directoryPath));		
				pathPlus(subDirectoryPath, subDir->DIR_Filename, subDir->DIR_Extension);	
				
				//子文件夹递归显示
				int countResultsInThisDirectory = showContentsInADirectory(file, subDirectoryPath, subDir, subDir);	
				
				subDirectoryCount ++;
				
				free(subDirectoryPath);												
			}
			else if(attribute == VALID_FILE){	
				subFileCount ++;	
				//如果是展示模式或者是搜寻模式，打印文件的路径，文件名，扩展名												
				if(mode != COUNT_MODE){												
					printValidFile(directoryPath, subDir);							
				}
			}
		}
	}

	//这个文件夹中既没有子文件夹，也没有有效文件，说明是一个空文件夹，在展示模式或者是搜寻模式下，输出该文件夹路径	
	if(subFileCount == 0 && subDirectoryCount == 0 && mode != COUNT_MODE){			
		printDirectoryPath(directoryPath);											
		printStr("\n\0");
	}
	
	int directoryPathLen = strlen(directoryPath);	
	int directoryPathDepth = directoryPathLen/11;		
	

	for(int j=0; j<11;j++){
		countResultNames[countResultLength*12+j] = directoryPath[directoryPathLen-11+j];
	}
	//把这个文件夹的层数，子文件夹个数，子文件个数写入数组中
	countResultLevels[countResultLength] = directoryPathDepth;			
	countResultNums[2*countResultLength] = subDirectoryCount;			
	countResultNums[2*countResultLength+1] = subFileCount;				
	
	countResultLength++;
	
	return (subDirectoryCount*100 + subFileCount);
}


/*----------------------------------------------------------------------------------------------------------------------------
功能：读取用户输入，根据不同输入做查询并输出结果
调用方法：searchContents
*/
void searchContentsInSpecificPath(){


		printStr(inputTip);										
		
		char inputStr[100];
		char* inputStrPtr = &inputStr[0];							
		scanf("%s",inputStrPtr);								
																
		//如果用户输入Q，退出
		if(strcmp(inputStrPtr, "Q") == 0) {						
			printStr(quitTip);
			continueProgram=FALSE;
			return;
		}
		
		else{
			
			file = fopen(floppyName, "r");	

			if(file == NULL){				
				printWarning(openFileFailedWarning);
				exit(1);						
			}
			
			Dir* dir2 = (Dir*)malloc(sizeof(Dir));				
			memset(dir2, 0, sizeof(Dir));					
			Dir* subDir2 = (Dir*)malloc(sizeof(Dir));		
			memset(subDir2, 0, sizeof(Dir));				
				
			//如果用户输入count指令，进入统计模式，读入路径
			if(strcmp(inputStrPtr, "count") == 0){				
				scanf("%s",inputStrPtr);						
				mode = COUNT_MODE;
			}
			else{											
				mode = SEARCH_MODE;
			}
			
			//不管是统计模式还是搜寻模式，首先对输入的路径进行标准化处理		
			int inputStrLen = strlen(inputStr);				
		
			int inputIsFile = 0;	
			int depth = 0;		
			
			for(int i=0; i<inputStrLen; i++){	
				if(inputStr[i] == '/'){		
					depth++;
				}
			}											
			
			if((inputStr[inputStrLen-1] != '/') && (mode == SEARCH_MODE)){
				inputIsFile = 1;	
			}
			
			if((inputStr[inputStrLen-1] != '/') && (mode == COUNT_MODE)){
				depth++;		
			}
					
			//所以字符数组的有效大小是(depth+inputIsFile)*11
			
			//接下来把用户的输入标准化，即每一层的名称都占满11个字节，便于搜寻时的比较
			
			char inputStdForm[(depth+inputIsFile)*11+1];	
			char* inputStdFormPtr = &inputStdForm[0];	
			
			//把inputStdForm字符数组的每一项都设为默认的空格
			for(int i=0; i<depth+inputIsFile; i++){
				for(int j=0; j<11; j++){
					inputStdForm[i*11+j] = ' ';
				}
			}
			inputStdForm[(depth+inputIsFile)*11] = 0;
			
			//逐个字符检查用户的输入以及标准化
			int j = 0, l = 0;								
			for(int i = 0;i < inputStrLen;i++){
				if(inputStr[i] == '/' && l <= 11){			
					j++;							
					l = 0;
				}
				else if(inputStr[i] == '.' && l <= 8){
					l = 8;	
				}
				else if(l > 10){
					printWarning(fileNameOverflowWarning);
					exit(1);
				}
				else if(inputStr[i] == '.' && l >= 8){	
					printWarning(fileNameOverflowWarning);	
					exit(1);
				}
				else if(inputStr[i] != '.' && inputStr[i] != '/'){
					inputStdForm[j*11+l] = inputStrPtr[i];
					l++;
				}
			}
			
			//如果是统计模式，初始化统计模式中用到的统计结果数组
			if(mode == COUNT_MODE){								
				for(int i=0; i<50; i++){
					countResultLevels[i] = 0;	
				}
				for(int i=0; i<100; i++){
					countResultNums[i] = 0;	
				}
				for(int i=0; i<600; i++){
					if(i % 12 == 11){
						countResultNames[i] = '\0';	
					}
					else{
						countResultNames[i] = ' ';	
					}
				}
				countResultLength = 0;		
			}
			
			//给定路径的实际深度为depth+inputIsFile， 需要搜寻的深度为depth	
			haveFound = FALSE;	
			searchContents(inputStdFormPtr, inputIsFile, depth+inputIsFile, depth, file, "", ROOT_START, dir2, subDir2);										
			
			//如果是统计模式，并找到了输入路径对应的文件夹，显示统计模式的统计结果
			if(mode == COUNT_MODE && haveFound == TRUE){		

				//统计结果数组中，每一个统计结果的深度减去最上层文件夹的深度，用于确定缩进量
				for(int i=0; i<countResultLength; i++){
					countResultLevels[i] -= countResultLevels[countResultLength-1];	
				}
				for(int i=countResultLength-1; i>=0; i--){				
					for(int l=0; l<countResultLevels[i]; l++){
						printStr("    \0");	
					}
					
					printDirectoryPath(&countResultNames[i*12]);
					printStr(" : \0");
					printNum(countResultNums[2*i+1]);
					printStr(countResultFilePart);
					printNum(countResultNums[2*i]);
					printStr(countResultDirectoryPart);
				}
			}
			
			fclose(file);	
			free(dir2);	
			free(subDir2);
		}
	
}

/*----------------------------------------------------------------------------------------------------------------------------
按照一个给定的路径，搜寻其中的内容并显示
*/
void searchContents(char* specificPath, int searchType, int depthInSpecificPath, int depthStillNeedToSearch, FILE* file, char* currentPath, int offset, Dir* dir, Dir* subDir){					
	//用于恢复现场
	long currentPosition = ftell(file); 
	
	//向下遍历depthStillNeedToSearch层，找到对应的文件夹
	while(depthStillNeedToSearch > 0){

		fseek(file, offset, SEEK_SET);     
		memset(dir, 0, sizeof(Dir));	
		fread(dir, sizeof(Dir), 1, file);

		if(isEmpty(dir)){				
			break;					
		}
		
		int attribute = getAttribute(dir);	
		
		if(attribute == DIRECTORY){		
			//如果目录条目所指的文件夹名称和给定路径的第n层一致
			if(strncmp(specificPath+(depthInSpecificPath-depthStillNeedToSearch-searchType)*11, dir->DIR_Filename,11) == 0){
				int fst_Clus = dir->DIR_FstClus[0] + dir->DIR_FstClus[1] * 0x10;
				fst_Clus = fst_Clus & 0x000000ff;								
				offset = (fst_Clus - 2) * 0x200 + DATA_START;
				depthStillNeedToSearch--;										
			}
			else{																
				offset += 32;													
			}
		}
		else{																	
			offset += 32;														
		}	
	}

	fseek(file, currentPosition, SEEK_SET);		
	
	//循环结束时，对于给定深度的文件夹的搜索已经结束
	if(depthStillNeedToSearch > 0){		
		if(mode==COUNT_MODE)
				printWarning(notADirectory);
			else
				printWarning(unknownFileWarning);	
	}
	
	else{															
		if(searchType == 1){										
			//在dir对应的文件夹路径中搜寻指定文件
			for(int i=0; i<16; i++){						

				readSubDir(file, offset + 32*i, subDir);	
		
				if(isEmpty(subDir) == TRUE){			
					break;	
				}
				else{		
					int attribute = getAttribute(subDir);						
					if(attribute == VALID_FILE){	
						
						//如果子目录条目所指文件的文件名和指定路径的文件名一样，则是所要寻找的文件
						if(strncmp(specificPath+(depthInSpecificPath-1)*11, subDir->DIR_Filename,11) == 0){
							showFileContent(file, subDir);				
							haveFound = TRUE;								
						}
					}
				}
			}
			//如果在dir对应的文件夹路径中循环搜寻结束后仍没有找到，那要么路径不对，要么是个文件
			if(haveFound == FALSE){												
				if(mode==COUNT_MODE)
					printWarning(notADirectory);
				else
					printWarning(unknownFileWarning);								
			}
		}
		else{					
			haveFound = TRUE;												
			showContentsInADirectory(file, specificPath, dir, subDir);
		}
	}
}

/*----------------------------------------------------------------------------------------------------------------------------
显示一个文件中的全部内容
*/
void showFileContent(FILE* file, Dir* fileDir){
	
	int fst_Clus = fileDir->DIR_FstClus[0] + fileDir->DIR_FstClus[1] * 0x10;
	fst_Clus = fst_Clus & 0x000000ff;							
	
	if(fst_Clus == 0){										
		printWarning(emptyFileWarning);	
	}
	else{											
		long currentPosition = ftell(file);						
		char* fileContentPtr = (char*)malloc(512); 		
		
		
		for(int FATComponent=fst_Clus;FATComponent < 0xff8;FATComponent = getClus(file, FATComponent)){
		//如果FAT项的值小于0xff8，说明文件内容还没结束，继续输出		
			int fileDataAddr = (FATComponent - 2) * 0x200 + DATA_START;			
			
			fseek(file, fileDataAddr, SEEK_SET);     							
			fread(fileContentPtr, 1, 512, file);					
			printStr(fileContentPtr);						
		}
		
		free(fileContentPtr);					
			
		fseek(file, currentPosition, SEEK_SET);	
	}
}


/*----------------------------------------------------------------------------------------------------------------------------
把新的文件夹的文件名、扩展名追加到新文件路径的后11位中。
*/
void pathPlus(char* newPath, char* newFileName, char* newFileExtension){
	int newPathLen = 0;		
	while(newPath[newPathLen] != 0){	
		newPathLen += 11;
	}
										
	for(int i = 0; i < 8; i++){			
		newPath[newPathLen+i] = newFileName[i];
	}	
											
	for(int i= 0; i < 3; i++){		
		newPath[newPathLen+8+i] = newFileExtension[i];
	}
}

/*----------------------------------------------------------------------------------------------------------------------------
读取一个子目录条目，保存到subDir中
*/
void readSubDir(FILE* file, int subOffset, Dir* subDir){
			
	fseek(file, subOffset, SEEK_SET);
	memset(subDir, 0, sizeof(Dir));	
	fread(subDir, sizeof(Dir), 1, file);

}

/*----------------------------------------------------------------------------------------------------------------------------
取得FAT表中第n项的簇号
*/
int getClus(FILE* file, int n){
	long currentPosition = ftell(file);					
	fseek(file, FAT_START, SEEK_SET);     				
	
	char* FATPtr = (char*)malloc(512);	
	
	fread(FATPtr, 1, 512, file);	
	
	int newN = n;
	//保证newN是偶数		
	if(n % 2 != 0){
		newN = n-1;													
	}
	
	char char1 = FATPtr[3*newN/2];	
	char char2 = FATPtr[3*newN/2+1];
	char char3 = FATPtr[3*newN/2+2];
	
	/*将三个字节的内容变成两个簇号
	如果写成“int FAT1 = (char2 & 0x0f) % 16 * 0x100 + char1;”，你就会发现原本是fff的值变成了eff
	原因就是计算机把ff的值作为-1，而不是255*/
	unsigned int FAT1 = (char2 & 0x0f) % 16 * 0x100 + (char1 & 0xf0) / 16 * 0x10 + (char1 & 0x0f) % 16;
	unsigned int FAT2 = (char3 & 0xf0) / 16 * 0x100 + (char3 & 0x0f) % 16 * 0x10 + (char2 & 0xf0) / 16;
	
	free(FATPtr);	

	fseek(file, currentPosition, SEEK_SET);
	
	if(n % 2 == 0){
		return FAT1;	
	}
	else{
		return FAT2;
	}
}

/*----------------------------------------------------------------------------------------------------------------------------
判断一个目录条目是否为空
*/
int isEmpty(Dir* dir){
	int i = 0;
	for(i=0; i<32; i++){			
		if(((char*)dir)[i] > 0){		
			return FALSE;						
		}
	}
	return TRUE;
}

/*----------------------------------------------------------------------------------------------------------------------------
判断一个目录条目是否有效及它所指对象的属性
*/
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



/*----------------------------------------------------------------------------------------------------------------------------
输出文件夹的路径
*/
void printDirectoryPath(char* path){
	prepareOutputDirectory();
	if(strlen(path)<1)
		return;
									
	for(int i=0;i < strlen(path)-1;i++){	
		if(path[i] != ' '){		
			my_print(&path[i], 1);
		}
		if(i%11 == 10){					
			my_print("/", 1);		
		}
	}
	
	if(path[strlen(path)-1] != '/' && path[strlen(path)-1] != ' ' ){
		my_print(&path[strlen(path)-1], 1);
	}
	prepareTerminal();	
}


/*----------------------------------------------------------------------------------------------------------------------------
输出包括文件的路径，文件名，扩展名
*/
void printValidFile(char* path, Dir* dir){
	printDirectoryPath(path);
	if(strlen(path)>0){
		prepareOutputDirectory();
		printStr("/\0");
	}	
	prepareOutputFile();
								
	for(int i=0; i<8; i++){		
		if(dir->DIR_Filename[i] != ' '){
			my_print(&dir->DIR_Filename[i], 1);	
		}
	}	
	printStr(".\0");		
							
	for(int i=0; i<3; i++){		
		if(dir->DIR_Extension[i] != ' '){
			my_print(&dir->DIR_Extension[i], 1);
		}
	}
	printStr("\n\0");
	
	prepareTerminal();				
}

/*----------------------------------------------------------------------------------------------------------------------------
输出数字
*/
void printNum(int num){
	char* number = (char*)malloc(5);
	memset(number,0,5);

	int size = 1;
	for(int temp = num;temp>9;temp/=10){
		size++;
	}
	for(int i = size-1;i>=0;i--){
		number[i] = num%10+'0';
		num/=10;
	}

	printStr(number);
	free(number);

}

/*----------------------------------------------------------------------------------------------------------------------------
输出字符串
*/
void printStr(char* str){
	my_print(str,strlen(str));							
}

/*----------------------------------------------------------------------------------------------------------------------------
输出系统提示（错误或者警告）
*/
void printWarning(char* warning){
	prepareWarning();
	my_print(warning,strlen(warning));	
	prepareTerminal();
}