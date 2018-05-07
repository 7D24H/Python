#include <stdio.h>

int main(){
	char ch;
	FILE *fp;
	fp = fopen("a.img","r");
	int i=9728;
	while(i>0){
		getc(fp);
		i--;
	}
	int j=1256;
	while(j>0){
		putchar(getc(fp));
		j--;
	}
	printf("hello");
}
