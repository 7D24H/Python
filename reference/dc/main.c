#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ROOT_START 0x2600//19*512=0x2600 根目录区起始位置
#define TRUE 1
#define FALSE 0
#define MAX 100//最多存储100个字节长的文件名或者路径

typedef int BOOL;
int BytsPerSec;	//每扇区字节数
int SecPerClus; //每簇扇区数
int RsvdSecCnt; //Boot记录占用的扇区数
int NumFATs;	//FAT表个数
int RootEntCnt; //根目录最大文件数
int FATSz;      //FAT扇区数
int RootEntrySize;	//某一个根目录条目长度
int Data_Start=0;	//存储数据区的开始位置
BOOL pathFound=FALSE; //存储是否找到文件
int numIndex=0;//存储当前存的是第几条
int blank=0;//存储当前的层数

//BPB从偏移11字节的位置开始
typedef struct {
	char	BPB_BytsPerSec[2];													//每扇区字节数
	char	BPB_SecPerClus[1];													//每簇扇区数
	char	BPB_RsvdSecCnt[2];													//Boot记录占用多少扇区
	char	BPB_NumFATs[1];														//共有多少FAT表
	short	BPB_RootEntCnt;													//根目录文件数最大值
	char	BPB_TotSec16[2];													//扇区总数
	char	BPB_Media[1];														//介质描述符
	char	BPB_FATSz16[2];														//每FAT扇区数  
	char	BPB_SecPerTrk[2];													//每磁道扇区数
	char	BPB_NumHeads[2];													//磁头数
	char	BPB_HiddSec[4];														//隐藏扇区数
	char	BPB_TotSec32[4];													//如果BPB_TotSec16为0 则由这个值记录扇区数

} BPB;

//根目录条目
typedef struct {
	char	DIR_Name[11];														//文件名8字节扩展名3字节
	char	DIR_Attr[1];														//文件属性
	char	DIR_Reserved[10];													//保留位
	char	DIR_WrtTime[2];														//最后一次写入时间
	char	DIR_WrtDate[2];														//最后一次写入日期
	short	DIR_FstClus;														//此条目对应的开始簇号
	char	DIR_FileSize[4];													//文件大小
} RootEntry;
//根目录条目一共32字节

//当前目录对应包含的文件数和目录数条目
typedef struct {
	char dirName[8];
	int  fileNum;
	int  dirNum;
	int  layer;	
}CountEntry;

CountEntry* countEntry[200];//存储每一层的文件数和目录数

void my_print(char* c,int length);
void change_color();
void reset_color();

void loadBPB(FILE* fat12);	//载入BPB
void readFileDir(FILE* file,char* path,int offset,RootEntry* root);	//读根目录区文件目录
void findPath(FILE* file,char* inputpath,char* path,int offset,RootEntry* root);//根据用户输入找到所有子路径
void fileFound(FILE* file,char* inputpath,char* path,RootEntry* root);//判断当前路径是否包含/等于输入路径
void emptyDirFound(char* inputpath,char* path); //找到空文件夹，直接判断是否包含
void countFileDir(FILE* file,char* inputpath, char* path,int offset,RootEntry* root,int blank);//计算输入路径下的文件和子目录数

void readFileContent(FILE* file,short fstClus);//读取某一文件的内容
void addToPath(char* oldPath,char* name);
void printFilePath(char* path,RootEntry* root);	//输出某一文件的路径
void printPath(char* path);	//输出某一路径
void printMsg(char* msg);//输出一些提示语句
int  getNextClus(FILE* fat12,int num);	//在FAT1表中读取下一个簇号
BOOL isDir(RootEntry* root);	//判断是否是子目录
BOOL isEmpty(RootEntry* root);	//判断此条目中是否为空
BOOL isValid(RootEntry* root); //判断文件名是否有效

int main(){
	FILE* fat12;
	fat12=fopen("abc.img","r");	//打开FAT12的映像文件
	//载入BPB
	loadBPB(fat12);
    
	//根目录一个条目的大小
	RootEntrySize = sizeof(RootEntry);
	//用于存储根目录中的一个条目,先全部置为0
    RootEntry* root=(RootEntry*)malloc(RootEntrySize);
    memset(root,0,RootEntrySize);

    //输出文件系统的所有目录
    readFileDir(fat12,"",ROOT_START,root);

    //接受用户输入
    char* input_msg="\nPlease input dir or count(exit with end):";
    char* notFound_msg="Unknown File :(\n";
    char* count="count";
   
    while(TRUE){ 
    	printMsg(input_msg);
    	char input[200];
    	char* input_ptr=&input[0];
    	// gets(input);
    	input_ptr=input;
    	scanf("%[^\n]",input_ptr);//这里真奇怪。。。怎么好像自动读入了我刚刚输入的字符
        getchar();
        if(strcmp(input_ptr,"end")==0){
        	break;
        }else{
        	//初始化
        	pathFound=FALSE;
        	if(strstr(input_ptr,count)){
        		//输入的count指令
        		blank=0;
        		numIndex=0;
        		memset(countEntry,0,200);
        		
                fseek(fat12,0,SEEK_SET);
                memset(root,0,RootEntrySize);
                //input_ptr指向count后面的路径
                input_ptr=&input[6];
                countFileDir(fat12,input_ptr, "",ROOT_START,root,blank);
				if(!pathFound){
        			printMsg(notFound_msg);
        		}else{
        			if(numIndex!=0){
        				int i=numIndex-1;
        				while(i>=0){
        					char* entry=(char*)malloc(100);
        					//从后往前输出每一个条目内容
        					char* file=" file,";
    						char* dir=" directory";
    						char* fileNum_ptr=(char*)malloc(2);
    						fileNum_ptr[0]=countEntry[i]->fileNum+0x30;
    						fileNum_ptr[1]=0;
    						char* dirNum_ptr=(char*)malloc(2);
    						dirNum_ptr[0]=countEntry[i]->dirNum+0x30;
    						dirNum_ptr[1]=0;
    						char* blank=" ";
    						//先输出缩进
    						int j=0;
    						for (j = 0; j < countEntry[i]->layer; ++j){
    							my_print(blank,1);
    						}
    	                    my_print(countEntry[i]->dirName,strlen(countEntry[i]->dirName));
    	                    my_print(":",1);
        					my_print(fileNum_ptr,strlen(fileNum_ptr));
        					my_print(file,strlen(file));
        					my_print(dirNum_ptr,strlen(dirNum_ptr));
        					my_print(dir,strlen(dir));
        					my_print("\n",2);
        					--i;
        				}
					}
        		}
            }else{
        		//输入的是路径或者文件名
        		fseek(fat12,0,SEEK_SET);
        		memset(root,0,RootEntrySize);
        		findPath(fat12,input_ptr,"",ROOT_START,root);
        		if(!pathFound){
        			printMsg(notFound_msg);
        		}
        	}
        }
    }
    free(root);
    fclose(fat12);
    return 0;
}

/*
*加载BPB各项的值
*/
void loadBPB(FILE* fat12){
	BPB* bpb = (BPB*)malloc(sizeof(BPB));
	//BPB从偏移11个字节处开始
	fseek(fat12,0x0b,SEEK_SET);
	fread(bpb,sizeof(BPB),1,fat12);	

	//计算数据区的起始地址
	int rootEntCnt = bpb->BPB_RootEntCnt;
	int dataSec = (rootEntCnt*32+0x200-1)/0x200;
	Data_Start = dataSec*0x200+ROOT_START;

	fseek(fat12,0,SEEK_SET);
	free(bpb);
}

/*
*输出文件系统存储的所有条目
*/
void readFileDir(FILE* file,char* path,int offset,RootEntry* root){
  	//返回为当前文件指针的位置 保护现场
  	long point=ftell(file);
  	//存储该子目录下的子目录和文件数
    int countDir=0;
    int countFile=0;
  	//指向该目录开头
  	fseek(file,offset,SEEK_SET);
  	do{
      memset(root,0,RootEntrySize);
      fread(root,RootEntrySize,1,file);	//读取根目录中的一个条目

      if(isDir(root)){
      	//如果是子目录,则去数据区读取对应的子目录条目
        int fst_Clus=root->DIR_FstClus;
        //将这层的子目录名/文件名添加到后面
        char* newPath=(char*)malloc(strlen(path)+0x10);
        memset(newPath,0,strlen(newPath));
        strcpy(newPath,path);
        //保护现场
		RootEntry saveRoot;//用于保存当前子目录信息
        memcpy(&saveRoot,root,RootEntrySize);
        addToPath(newPath,root->DIR_Name);
        
        //读取存储在数据区内的子目录信息
        readFileDir(file,newPath,(Data_Start+(fst_Clus-2)*0x200),root);
        
        //恢复现场
        memcpy(root,&saveRoot,RootEntrySize);
        free(newPath);
        countDir++;
      }else{
      	//说明已经读到了某一个文件处，打印此时的路径信息即可
      	if(isValid(root)){
      		printFilePath(path,root);
      		countFile++;
        }
      }
  	}while (!isEmpty(root));
    
    if(countDir==0&&countFile==0){
    	printPath(path);	//空文件夹
    }
    fseek(file,point,SEEK_SET);	//恢复现场
}

/*
*遍历所有路径
*/
void findPath(FILE* file,char* inputpath,char* path,int offset,RootEntry* root){
	//返回为当前文件指针的位置 保护现场
  	long point=ftell(file);
  	//存储该子目录下的子目录和文件数
    int countDir=0;
    int countFile=0;
  	//指向该目录开头
  	fseek(file,offset,SEEK_SET);
  	do{
      memset(root,0,RootEntrySize);
      fread(root,RootEntrySize,1,file);	//读取根目录中的一个条目

      if(isDir(root)){
      	countDir++;
      	//如果是子目录,则去数据区读取对应的子目录条目
        int fst_Clus=root->DIR_FstClus;
        //将这层的子目录名/文件名添加到后面
        char* newPath=(char*)malloc(strlen(path)+0x10);
        memset(newPath,0,strlen(newPath));
        strcpy(newPath,path);
        //保护现场
		RootEntry saveRoot;//用于保存当前子目录信息
        memcpy(&saveRoot,root,RootEntrySize);
        addToPath(newPath,root->DIR_Name);
        
        //读取存储在数据区内的子目录信息
        findPath(file,inputpath,newPath,((fst_Clus-2)*0x200+Data_Start),root);
        
        //恢复现场
        memcpy(root,&saveRoot,RootEntrySize);
        free(newPath);
        
      }else{
      	//说明已经读到了某一个文件处，打印此时的路径信息即可
      	if(isValid(root)){
      		countFile++;
      		fileFound(file,inputpath,path,root);
        }
      }
  	}while (!isEmpty(root));
    
    if(countDir==0&&countFile==0){
    	emptyDirFound(inputpath,path);	//空文件夹
    }
    fseek(file,point,SEEK_SET);	//恢复现场
}

/*
*判断空文件夹路径是否包含输入的路径
*/
void emptyDirFound(char* inputpath,char* path){
	//先将path转成标准路径格式
	int i=0;
	char formatPath[100];
	char* formatPath_ptr=&formatPath[0];
    int index=0;

	while(i<strlen(path)){
		if(path[i]!=' '){
			formatPath[index]=path[i];
			++index;
		}
		if(i%8==7){
			formatPath[index]='/';
			++index;
		}
		++i;
	}
	formatPath[index]='\0';
	if(strstr(formatPath_ptr,inputpath)){
		pathFound=TRUE;
		change_color();
		my_print(formatPath_ptr,strlen(formatPath_ptr));
		my_print("\n",2);
		reset_color();
	}
}

/*
*判断含有文件的路径是否包含或等于输入的路径
*/
void fileFound(FILE* file,char* inputpath,char* path,RootEntry* root){
	//先将path转成标准路径格式
	int i=0;
	char formatPath[100];
	char* formatPath_ptr=&formatPath[0];
    int index=0;

	while(i<strlen(path)){
		if(path[i]!=' '){
			formatPath[index]=path[i];
			++index;
		}
		if(i%8==7){
			formatPath[index]='/';
			++index;
		}
		++i;
	}
	int indexOfDir=index;
	for(i=0;i<8;i++){
		if(root->DIR_Name[i]==' '){
			break;
		}
		formatPath[index]=root->DIR_Name[i];
		++index;
	}
	formatPath[index]='.';
	++index;
	for(i=8;i<11;i++){
		if(root->DIR_Name[i]==' '){
			break;
		}
		formatPath[index]=root->DIR_Name[i];
		++index;
	}
	formatPath[index]='\0';

	//判断该路径是否和输入的路径一样，或者包含输入的路径
	if(strstr(formatPath_ptr,inputpath)){
        pathFound=TRUE;
        //判断输入的路径是否有文件
        if (strcmp(formatPath_ptr,inputpath)==0){
        	readFileContent(file,root->DIR_FstClus);
        }else{
        	//输入的只是目录
        	change_color();
			int i = 0;
			for (; i < indexOfDir; ++i) {
				my_print(&formatPath[i],1);
			}
			reset_color();
			for(;i < index; ++i) {
				my_print(&formatPath[i],1);
			}
			my_print("\n",2);
        }
	}
}

/*
*输出文件里的内容，可以超过512B
*/
void readFileContent(FILE* file,short fst_Clus){
	unsigned int clus=fst_Clus;
	long point=ftell(file);
	//存储每一个簇里的内容
	char* content=(char*)malloc(0x200);

	while(clus<0xFF8){
		if(clus==0xFF7){
			my_print("Bad cu",6);
			break;
		}
		int offset=(clus-2)*0x200+Data_Start;
		fseek(file,offset,SEEK_SET);
		fread(content,0x200,1,file);

		//输出content中的内容
		int i=0;
		while(i<0x200){
			if(content[i]=='\0'||content[i]==0x0D){
				break;
			}
			my_print(&content[i],1);
			++i;
		}
		clus=getNextClus(file,clus);
	}

	free(content);
	fseek(file,point,SEEK_SET);
}

/*
*计算输入的路径下包含多少个文件和子目录
*/
void countFileDir(FILE* file, char* inputpath, char* path,int offset,RootEntry* root,int blank){
//返回为当前文件指针的位置 保护现场
  	long point=ftell(file);
  	//存储该子目录下的子目录和文件数
    int countDir=0;
    int countFile=0;
  	//指向该目录开头
  	fseek(file,offset,SEEK_SET);
  	do{
      memset(root,0,RootEntrySize);
      fread(root,RootEntrySize,1,file);	//读取根目录中的一个条目

      if(isDir(root)){

      	//如果是子目录,则去数据区读取对应的子目录条目
        int fst_Clus=root->DIR_FstClus;
        //将这层的子目录名/文件名添加到后面
        char* newPath=(char*)malloc(strlen(path)+0x10);
        memset(newPath,0,strlen(newPath));
        strcpy(newPath,path);
        //保护现场
		RootEntry saveRoot;//用于保存当前子目录信息
        memcpy(&saveRoot,root,RootEntrySize);
        addToPath(newPath,root->DIR_Name);
        blank=blank+2;
        //读取存储在数据区内的子目录信息
        countFileDir(file,inputpath,newPath,(Data_Start+(fst_Clus-2)*0x200),root,blank);
        blank=blank-2;
        //恢复现场
        memcpy(root,&saveRoot,RootEntrySize);
        free(newPath);
        countDir++;
      }else{
      	//说明已经读到了某一个文件处，判断此时的路径是否等于输入的路径
      	if(isValid(root)){
      		    //先将path转成标准路径格式
				int i=0;
				char formatPath[100];
				char* formatPath_ptr=&formatPath[0];
    			int index=0;

				while(i<strlen(path)){
					if(path[i]!=' '){
						formatPath[index]=path[i];
						++index;
				}
				if(i%8==7){
					formatPath[index]='/';
					++index;
				}
				++i;
				}
				int indexOfDir=index;
				for(i=0;i<8;i++){
					if(root->DIR_Name[i]==' '){
						break;
					}
					formatPath[index]=root->DIR_Name[i];
					++index;
				}
				formatPath[index]='.';
				++index;
				for(i=8;i<11;i++){
					if(root->DIR_Name[i]==' '){
						break;
					}
					formatPath[index]=root->DIR_Name[i];
					++index;
				}
				formatPath[index]='\0';

      			if(strcmp(formatPath_ptr,inputpath)==0){
      				//若输入的是文件路径
      				pathFound=TRUE;
      				char* notDir_msg=strcat(formatPath," is not a directory!");
      				printMsg(notDir_msg);
      				break;
      			}
      			countFile++;
        }
      }
  	}while (!isEmpty(root));
    
    //判断此时的path是否包含输入的目录
    //若包含，则取出最后8个字节
    //先将path转成标准路径格式
				int i=0;
				char formatPath[100];
				char* formatPath_ptr=&formatPath[0];
    			int index=0;

				while(i<strlen(path)){
					if(path[i]!=' '){
						formatPath[index]=path[i];
						++index;
				}
				if(i%8==7){
					formatPath[index]='/';
					++index;
				}
				++i;
				}
				int indexOfDir=index;
				for(i=0;i<8;i++){
					if(root->DIR_Name[i]==' '){
						break;
					}
					formatPath[index]=root->DIR_Name[i];
					++index;
				}
				formatPath[index]='.';
				++index;
				for(i=8;i<11;i++){
					if(root->DIR_Name[i]==' '){
						break;
					}
					formatPath[index]=root->DIR_Name[i];
					++index;
				}
				formatPath[index]='\0';

    if(strstr(formatPath_ptr,inputpath)&&(blank>0)){

    	pathFound=TRUE;
    	//保存当前目录的文件数和子目录数
    	CountEntry* entry=(CountEntry*)malloc(sizeof(CountEntry));
    	int i=0;
    	int sumFile=0;
    	int sumDir=0;
    	for(i=numIndex-1;i>=0;i--){
    		if(countEntry[i]->layer==blank){
    			//逐个向上访问每一个条目的层数
    			//如果碰上相同的层数则结束循环
    			break;
    		}else if(countEntry[i]->layer==blank+2){
    			//如果层数比它大一
    			//则将其所包含的目录数和文件数加进去
    			sumDir=countEntry[i]->dirNum+sumDir;
    			sumFile=countEntry[i]->fileNum+sumFile;
    		}
    	}

    	int index=0;
    	int len=strlen(path);
    	for(i=len-8;i<len;i++){
    		if(path[i]!=' '){
    			entry->dirName[index]=path[i];
    			++index;
    		}
    	}
    	entry->fileNum=countFile+sumFile;
    	entry->dirNum=countDir+sumDir;
    	entry->layer=blank;
    	countEntry[numIndex]=entry;
    	numIndex++;
    	/*
    	char* dirName=(char*)malloc(100);
    	char* file=" file,";
    	char* dir=" directory";
    	char* fileNum_ptr=(char*)malloc(2);
    	fileNum_ptr[0]=countFile+0x30;
    	fileNum_ptr[1]=0;
    	char* dirNum_ptr=(char*)malloc(2);
    	dirNum_ptr[0]=countDir+0x30;
    	dirNum_ptr[1]=0;

    	int i=0;
    	int index=0;
    	int len=strlen(path);
    	//先添加缩进
    	for (i = 0; i < blank; ++i){
    		dirName[index]=' ';
    		++index;
    	}
    	for(i=len-8;i<len;i++){
    		if(path[i]!=' '){
    			dirName[index]=path[i];
    			++index;
    		}
    	}
    	dirName[index]=':';
    	dirName[++index]=0;
    	//TODO 这里fileNum多输出了一个0
    	strcat(dirName,fileNum_ptr);
    	strcat(dirName,file);
    	strcat(dirName,dirNum_ptr);
    	strcat(dirName,dir);
    	
    	num[numIndex]=dirName;
    	numIndex++;
    	*/

    }
    fseek(file,point,SEEK_SET);	//恢复现场
}
/*
*将8位文件夹名添加到path后面
*/
void addToPath(char* path,char* name){
  int p=0;
  //将p指向path的后面一位
  while(path[p]!=0){
     p+=8;
  }
  int i=0;
  for(i=0;i<8;i++){
     path[p+i]=name[i];
  }
  // path[p+8]=0;
}

/*
*输出一直到某文件的路径
*/
void printFilePath(char* path,RootEntry* root){
	char* p = "/";
	int i=0;
	//输出文件的路径名
	change_color();
	while (i < strlen(path)){
		if (path[i] != ' '){
			my_print(&path[i], 1);
		}
		if (i % 8 == 7){
			my_print(p, 1);
		}
		i++;
	}
	
	//输出文件名
	reset_color();
	for(i=0;i<8;i++){
		if(root->DIR_Name[i]==' '){
			break;
		}
		my_print(&root->DIR_Name[i],1);
	}
	my_print(".",1);
	for (i = 8; i < 11; ++i){
		if(root->DIR_Name[i]==' '){
			break;
		}
		my_print(&root->DIR_Name[i],1);
	}

	my_print("\n",2);

}

/*
*输出路径
*/
void printPath(char* path){
	char* p = "/";
	int i=0;
	change_color();
	while (i < strlen(path)){
		if (path[i] != ' '){
			my_print(&path[i], 1);
		}
		if (i % 8 == 7){
			my_print(p, 1);
		}
		i++;
	}
	reset_color();
	my_print("\n",2);
}

/*
*获得下一个簇号
*/
int getNextClus(FILE *fat12,int num){
	//FAT1扇区开始位置
	int fat1Base=0x200;
	//该FAT项起始位置对应的偏移量
	int clusPos=fat1Base+num*3/2;
	//一个FAT表项存储为3个字节，若为奇数，则取第二个字节起始位置。若为偶数则取第一个字节起始地址
	
	//读出该FAT项所在的两个字节
	unsigned short bytes;
	unsigned short *bytes_ptr=&bytes;
	fseek(fat12,clusPos,SEEK_SET);
	fread(bytes_ptr,1,2,fat12);

	//偶数，取byte1和byte2的低4位,即bytes％2^12
	//奇数，取byte2和byte1的高4位
	if(num%2==0){
        return bytes%0x01000;
	}else{
		return bytes>>4;
	}
}

/*
*判断是不是子目录
*/
BOOL isDir(RootEntry* root){

	char c = root->DIR_Name[0];
	if(c < 0x30 || c > 0x7a)						
		return FALSE;

	int i = 0x00;
	for (i = 0x00; i < 0x08; i++){
		c = root->DIR_Name[i];
		if ( c < 0x20 || c > 0x7d){
			return FALSE;
		}
	}
	for (i = 0x08; i < 0x0a; i++){
		c = root->DIR_Name[i];
		if( c < 0x20 || c > 0x7d){
			return FALSE;
		} else if( c != 0x20 ){
			return FALSE;
		}
	}
	return TRUE;
}

/*
*判断此条目是否为空
*/
BOOL isEmpty(RootEntry* root){
	int i=0;
	for(i=0;i<0x20;i++){
		if(((char*)root)[i]> 0){
			return FALSE;
		}
	}
	return TRUE;
}

/*
*判断文件名是否有效
*/
BOOL isValid(RootEntry* root){
	int j = 0;
		for (j = 0; j < 11; j++){
			char c = root->DIR_Name[j];
			if (! ((c >= '0' && c <= '9') 
				|| (c >= 'a' && c <= 'z')
				|| (c >= 'A' && c <= 'Z')
				|| c == ' ')){
				return FALSE;
			} 
		}
	return TRUE;
}

void printMsg(char* msg){
	int i=0;
	for(i=0;i<strlen(msg);i++){
		my_print(&msg[i],1);
		//printf("%c",msg[i]);
	}
}
