#include<stdio.h>
#include<stdlib.h>
#include<string.h>

char root[10][12];   //十层目录，每层文件名最多10字节
int byteOffset[10];
int byteNum[10];
int canFind;
int isRoot ;
int deepOfDir;
int RootEntCnt;     //根目录最大文件数
char root2[10][12]; //用于存储搜索的根目录
int deepOfDir2;     //用于存储搜索的根目录长度-1

int fileOrDirByteOffset;  //输出文件内容或目录统计时需要的偏移
int type;                 //0 输出文件目录名，1输出内容 2,输出统计信息
int searchFileType;       //0未找到文件，1，文件为目录，2文件类型正确
char filename[12];        //搜索文件名字
int fileClus;             //文件的簇

int BytsPerSec;     //每扇区字节数
int FATSz;          //FAT扇区数
int SecPerClus;     //每簇扇区数
int RsvdSecCnt;     //boot记录占用扇区数
int NumFATs;        //FAT表个数
#pragma pack (1) /*指定按1字节对齐*/
struct BPB
{
    unsigned short  BPB_BytsPerSec;    //每扇区字节数  
    unsigned char   BPB_SecPerClus;    //每簇扇区数  
    unsigned  short  BPB_RsvdSecCnt;    //Boot记录占用的扇区数  
    unsigned char   BPB_NumFATs;       //FAT表个数  
    unsigned short  BPB_RootEntCnt;    //根目录最大文件数  
    unsigned short  BPB_TotSec16;  
    unsigned char   BPB_Media;  
    unsigned short  BPB_FATSz16;        //FAT扇区数  
    unsigned short  BPB_SecPerTrk;  
    unsigned short  BPB_NumHeads;  
    unsigned int    BPB_HiddSec;  
    unsigned int    BPB_TotSec32;       //如果BPB_FATSz16为0，该值为FAT扇区数
  
};
struct RootItem
{
  char    DIR_Name[11];
  unsigned char    DIR_Attr;              //文件属性 0x20为文件，0x10为目录
  char    save[10];
  unsigned short   DIR_WrtTime;
  unsigned short   DIR_WrtDate;
  unsigned short   DIR_FstClus;
  unsigned int   DIR_FileSize;
};
struct Count
{
  int dirNum[20];
  int fileNum[20];
  char name[20][12];
  int spaceNum[20];
  int deep; 
};

void prepareOutputDirectory();
void prepareOutputFile();
void prepareWarning();
void prepareTerminal();

unsigned int getFATValue(int clus)
{
  FILE* fat12 = fopen("a.img","rb");
  int pos = RsvdSecCnt*BytsPerSec+clus/2*3+(clus+1)%2;
  unsigned short base;
  unsigned short add;
  unsigned short all;
  unsigned short* all_ptr = &all;
  int sign = fseek(fat12,pos,SEEK_SET);  
  if (sign == -1)   
    printf("getFATValue fseek失败");  
  sign = fread(all_ptr,1,2,fat12);  
  if (sign != 2)  
    printf("getFATValue fread 失败");  
  if(clus%2==0) 
  {
    base = all>>8;
    //add是FAT高四位，
    add = all<<12;
    add = add>>4;
    return (add+base);
  }
  else
  {
    base = all<<8;
    base = base>>4;
    add =  all>>12;
    return (base+add);
  }
   
}
void printDir(char* dir)
{
prepareOutputDirectory();
 // printf("%s",dir);
asmPrint(dir,strlen(dir));
prepareTerminal();
}
int judgeChar(char a)
{
  if(a>=48&&a<=57||a>=65&&a<=90||a>=97&&a<=122||a==' ')
    return 1;
  else
    return 0;
}
void printMessage(char* message)
{ prepareOutputFile();
  printf("%s",message);
  prepareTerminal();}
void fillBPB(FILE* fat12,struct BPB* bpb_ptr)
{
  int sign = fseek(fat12,11,SEEK_SET);
  if(sign==-1)
  {
    printf("there are error in fseek");
//	return;
  }
  sign = fread(bpb_ptr,1,25,fat12);
  if(sign!=25)
  {
  	printf("there are error in fread");
//	return;
  }
  SecPerClus = bpb_ptr->BPB_SecPerClus;
  BytsPerSec = bpb_ptr->BPB_BytsPerSec;
  RootEntCnt = bpb_ptr->BPB_RootEntCnt;
  RsvdSecCnt = bpb_ptr->BPB_RsvdSecCnt;
  FATSz = bpb_ptr->BPB_FATSz16;
  NumFATs = bpb_ptr->BPB_NumFATs;
  //printf("每簇有%d扇区\n",SecPerClus);
  //printf("每扇区有%d个字节\n",BytsPerSec);
 // printf("根目录文件数最大值%d\n",RootEntCnt);
 // printf("Boot记录占用%d扇区\n",RsvdSecCnt);
//  printf("每FAT表扇区数%d\n",FATSz);
 // printf("FAT表个数%d\n",NumFATs);
 // printf("根目录项长度%d\n",sizeof(struct RootItem));
	
}
int getByteOffset(FILE* fat12,int isPrintContent)
{
   int rootMatch = 1;
}
void printDirAndFileName(FILE* fat12,int base,int allBytes,int type)
{
  //是否可输出
  int canPrint = 1;
  //deepOfDir2=-1时，输出所有
  if(deepOfDir2 >=0)
  {
    for(int root2Index = 0;root2Index<=deepOfDir2;root2Index++)
	{
	  if(deepOfDir2>deepOfDir)
	  {
	    canPrint = 0;
		break;
	  }
	  if(strcmp(root[root2Index],root2[root2Index])!=0)
	  {
	    canPrint = 0;
		break;
	  }
	}
    if(canPrint)
      canFind = 1;
    //类型是输出文件内容和统计信息时不输出文件名
    if(type==1||type==2)
      canPrint = 0;
  }
//输出目录信息
  if(deepOfDir!=-1)
  {
    for(int rootIndex=0;rootIndex<=deepOfDir;rootIndex++)
    { 
	  if(canPrint)
	  {
        printMessage("/"); 
        printMessage(root[rootIndex]);
      }
	}
  }
  if(canPrint)
    printMessage("/:\n");
  struct RootItem* rootItem = (struct RootItem*)malloc(sizeof(struct RootItem)); 
  //此目录下子目录的信息                                                 
  char childDirName[10][11];
  int childDirNum = 0;
  int childByteOffset[10];
  int childByteNum[10] ;
  char realName[12];
  for(int i=0;i<allBytes;i+=32) 
  { 
   
    int sign = fseek(fat12,base,SEEK_SET);
	base += 32;
	if(sign==-1)
	  printf("there are error in print name when fseek");
	sign = fread(rootItem,1,32,fat12);
//	printf("属性：%d",rootItem->DIR_Attr); 
	if(sign==-1)
	   printf("there are error in print ");
	//空文件名不输出
	if(rootItem->DIR_Name[0]=='\0')
	{
	 // printf("文件名为空\n");
	  continue;
	}//非文件与非目录不输出 
    if((rootItem->DIR_Attr^0x20)!=0&&(rootItem->DIR_Attr^0x10)!=0)
	{
	  //printf("异或结果%d\n",rootItem->DIR_Attr^0x20);
	  //printf("非目录与文件\n");
	  continue;
	}//文件名不符合要求的文件不输出
	int match = 1;
    for(int judge=0;judge<11;judge++)
	{
	  if(!judgeChar(rootItem->DIR_Name[judge]))
	    {
		  match=0;
		  break;
		}
	}
	if(!match)
	  continue;
    //普通文件
	if((rootItem->DIR_Attr^0x20)==0)
	{

	  int isFirstSpace = 1;
	  int temp = 0;
	  for(int nameIndex=0;nameIndex<11;nameIndex++)
	  {
	   if(rootItem->DIR_Name[nameIndex]!=' ')
	   {  
	      realName[temp++] = rootItem->DIR_Name[nameIndex]; 
	   }
	   else
	   {  
	      if(isFirstSpace)
		  {
		    realName[temp++] = '.';
		  	isFirstSpace = 0;
		  }
	   }
	  }
	  realName[temp] = '\0';
	  if(canPrint)
	  {
	    printMessage(realName);
	    printMessage(" ");
	  }
          //type==1表示输出文件内容 canfind表示目录匹配
          if(type==1&&canFind)
          { 
            if(strcmp(realName,filename)==0)
              {
                //表示找到文件
                searchFileType = 2;
                fileClus = rootItem->DIR_FstClus;
                return;
              }
          }
	}

	//目录
	else
	{
	//处理目录名字
     int temp = 0;
	 for(int nameIndex=0;nameIndex<11;nameIndex++)
	   {
	     if(rootItem->DIR_Name[nameIndex]!=' ')
	        {  
	          realName[temp++] = rootItem->DIR_Name[nameIndex]; 
	        }
         else
	        { 
			  realName[temp++] = '\0';
	          break;
	        }
	   }
          //type==1表示输出文件内容 canfind表示目录匹配
          if(type==1&&canFind)
          { 
            if(strcmp(realName,filename)==0)
              {
                //表示名字匹配，但所搜寻为文件而得到目录
                searchFileType = 1;
              }
          }
          //需要输出统计数据，且所要求目录的前缀（除末尾目录）匹配
          if(type==2&&canFind)
          {
            if(strcmp(realName,root2)==0)
            {
                searchFileType = 1;
                fileClus = rootItem->DIR_FstClus;
                return;
            }
          }
	  strcpy(childDirName[childDirNum],realName);
	  // 偏移字节数 =（引导扇区数+FAT表扇区数+根目录扇区数+数据区扇区数）×每扇区字节数
      childByteOffset[childDirNum] = (RsvdSecCnt+NumFATs*FATSz+(RootEntCnt*32+BytsPerSec-1)/BytsPerSec+\
	  (rootItem->DIR_FstClus-2)*SecPerClus)*BytsPerSec;
      childByteNum[childDirNum] = rootItem->DIR_FileSize;
//	  printf("子目录长度（DIR——FileSize）%d\n",rootItem->DIR_FileSize);
	  if(canPrint)
	  {
	    printDir(realName);
	    printMessage(" ");
	  }
	  childDirNum++;
	}
  }
  if(canPrint)
    printMessage("\n");
  //不是输出文件目录名且目录前缀匹配，则返回
  if(canFind&&type!=0)
    return;
  for(int j=0;j<childDirNum;j++)
    {
      isRoot = 0;
      deepOfDir++;
	  strcpy(root[deepOfDir],childDirName[j]);
	  byteOffset[deepOfDir] = childByteOffset[j];
	  byteNum[deepOfDir] = childByteNum[j];
	  //原先的fat12文件指针改变，需要打开一个新的文件
	  //FILE* fat12_2 = fopen("./lab2.img","rb");
//	  printf("子目录基地址%d,子目录长度%d\n",byteOffset[deepOfDir],byteNum[deepOfDir]);
	  printDirAndFileName(fat12,byteOffset[deepOfDir],512,type);//byteNum[deepOfDir]);
	  deepOfDir--;
	}

  free(rootItem);
}
void readFile(FILE* fat12,int clus)
{
  int base = (RsvdSecCnt+NumFATs*FATSz+(RootEntCnt*32+BytsPerSec-1)/BytsPerSec+\
	  (clus-2)*SecPerClus)*BytsPerSec;
  char* content = (char*)malloc(sizeof(char)*512);
  fseek(fat12,base,SEEK_SET);
  fread(content,1,512,fat12);
  unsigned int fatValue = getFATValue(clus);
  if(fatValue==0xFF7)
    printMessage("坏簇");
  else if(fatValue>=0xFF8)
    {
      printMessage(content);
      printMessage("\n");
    }
  else
    {
      printMessage(content);
      readFile(fat12,fatValue);
      printMessage("\n");
    } 
  free(content);
}
struct Count* setCountTable(FILE* fat12,int clus,int spaceNum,struct Count* count)
{
  int dirNum = 0;
  int fileNum = 0;
  int deep = count->deep;
  int baseDeep = deep;
  int base = (RsvdSecCnt+NumFATs*FATSz+(RootEntCnt*32+BytsPerSec-1)/BytsPerSec+\
	  (clus-2)*SecPerClus)*BytsPerSec;
  struct RootItem* rootItem = (struct RootItem*)malloc(sizeof(struct RootItem));
//  struct Count* count = (struct Count*)malloc(sizeof(struct Count));
  for(int i=0;i<512;i+=32)
  {
    int sign = fseek(fat12,base,SEEK_SET);
	if(sign==-1)
	  printf("there are error in print name when fseek");
	sign = fread(rootItem,1,32,fat12);
//	printf("属性：%d",rootItem->DIR_Attr); 
	if(sign==-1)
	   printf("there are error in print ");
//判断符合条件的dir和file
        if(rootItem->DIR_Name[0]=='\0')
	{
	 // printf("文件名为空\n");
	  continue;
	}//非文件与非目录不输出 
    if((rootItem->DIR_Attr^0x20)!=0&&(rootItem->DIR_Attr^0x10)!=0)
	{
	  //printf("异或结果%d\n",rootItem->DIR_Attr^0x20);
	  //printf("非目录与文件\n");
	  continue;
	}//文件名不符合要求的文件不输出
	int match = 1;
    for(int judge=0;judge<11;judge++)
	{
	  if(!judgeChar(rootItem->DIR_Name[judge]))
	    {
		  match=0;
		  break;
		}
	}
	if(!match)
	  continue;
//结束判断
    //普通文件
    if((rootItem->DIR_Attr^0x20)==0)
      { 
          fileNum++;
      }
    //目录
    else
      {
        dirNum++;
        int temp = 0;
        char realName[12];
	 for(int nameIndex=0;nameIndex<11;nameIndex++)
	   {
	     if(rootItem->DIR_Name[nameIndex]!=' ')
	        {  
	          realName[temp++] = rootItem->DIR_Name[nameIndex]; 
	        }
         else
	        { 
			  realName[temp++] = '\0';
	          break;
	        }
	   }
        deep++;
        count->deep = deep;
        strcpy(count->name[deep],realName);
        count->spaceNum[deep] = spaceNum+2;
	setCountTable(fat12,rootItem->DIR_FstClus,spaceNum+2,count);
        //struct Count* returnCount = getCount(fat12,rootItem->DIR_FstClus,spacenum+2,realName);
        deep = count->deep;
        dirNum += count->dirNum[deep];
	fileNum += count->fileNum[deep];
        //free(returnCount);
      }
  } 
  count->dirNum[baseDeep] = dirNum;
  count->fileNum[baseDeep] = fileNum;
  free(rootItem);
}
int getByteOfData(FILE* fat12);
int main()
{
  FILE* fat12 = fopen("a.img","rb");
  struct BPB bpb; 
  struct BPB* bpb_ptr = (struct BPB*)malloc(sizeof(struct BPB));
  //struct BPB* bpb_ptr = &bpb;
  //printf("char大小：%d\n",sizeof(unsigned char));
  fillBPB(fat12,bpb_ptr);
  
  char* input = (char*)malloc(sizeof(char)*100);
  while(1)
  {
	asmPrint(">",1);
    //初始化
    searchFileType = 0;
    deepOfDir = -1;
    deepOfDir2 = -1;
    isRoot = 1;
    fileClus = 0;
    canFind = 0;
    //scanf("%[^\n]",input);
    gets(input);
	printf("input: %s\n",input);
	if(strlen(input)==2||strlen(input)==4)
	{
	//主目录
	  if(strcmp(input,"ls")==0)
	  {
	    int base = (RsvdSecCnt+NumFATs*FATSz)*BytsPerSec;
		int allBytes = ((RootEntCnt*32+BytsPerSec-1)/BytsPerSec)*BytsPerSec;
//		printf("根目录起始字节偏移%d. 根目录字节数%d\n",base,allBytes);
		printDirAndFileName(fat12,base,allBytes,0);
	  }
	  else if(strcmp(input,"exit")==0)
	  {
	    break;
	  }
	  else 
	  {
	    printf("input error!\n");
	  }
	  deepOfDir = -1;
	  continue;
	}
	char* save = NULL;
	char* order = strtok_r(input," ",&save);
    char* path = strtok_r(NULL," ",&save);
	char* try = strtok_r(NULL," ",&save);
	printf("path:%s\n",path);
	if(strcmp(order,"ls")==0)
	{
	  //输出指定目录
	  // printf("指定目录");
	  char* save2 = NULL;
	  char* dir;
	  while((dir=strtok_r(path,"/",&save2))!=NULL)
	  {
	    deepOfDir2++;
	    strcpy(root2[deepOfDir2],dir);
//		printf("子目录%s\n",dir);
		path = NULL;
	  }
//      printf("子目录0%s",root2[0]);
        int base = (RsvdSecCnt+NumFATs*FATSz)*BytsPerSec;
		         int allBytes = ((RootEntCnt*32+BytsPerSec-1)/BytsPerSec)*BytsPerSec;
		 //      printf("根目录起始字节偏移%d. 根目录字节数%d\n",base,allBytes);
		         printDirAndFileName(fat12,base,allBytes,0);
            if(!canFind)
	      {
 		printMessage("不能找到指定目录"); 
  	      }
	    canFind = 0;

    }
	else if(strcmp(order,"cat")==0)
	{
	  //输出路径文件内容
	  char* save3 = NULL;
	  char* dir;
	  while((dir=strtok_r(path,"/",&save3))!=NULL)
	  {
	    deepOfDir2++;
	    strcpy(root2[deepOfDir2],dir);
//		printf("子目录%s\n",dir);
		path = NULL;
	  }
          //没有输入输出文件路径
          if(deepOfDir2==-1)
          {
            printMessage("没有输入文件路径"); 
          }
          else
          {
            strcpy(filename,root[deepOfDir2]);
            deepOfDir2--;
       int base = (RsvdSecCnt+NumFATs*FATSz)*BytsPerSec;
		         int allBytes = ((RootEntCnt*32+BytsPerSec-1)/BytsPerSec)*BytsPerSec;
            printDirAndFileName(fat12,base,allBytes,1);
            if(canFind&&searchFileType==2)
            {
              //输出文件内容
              readFile(fat12,fileClus);
            }
            else
            {
              if(searchFileType==0)
                printMessage("无法找到指定文件");
              else if(searchFileType==1)
                printMessage("不是一个普通文件");
            }
          }
	}
	else if(strcmp(order,"count")==0)
	{
	  //输出目录及子目录下所有子目录数和文件数，有顺序和缩进关系
          
          //struct Count* setCountTable(FILE* fat12,int clus,int spaceNum,struct Count* count);
	}
	else
	{
	printf("输入命令错误!\n");
	}
	deepOfDir = -1;
  }
  free(input);
}
