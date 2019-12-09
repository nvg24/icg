%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include "lex.yy.c"

typedef struct tacListNode_impl
{
	char op;
	char *op1;
	char *op2;
	char *res;
	int tacIndex;
	struct tacListNode_impl* next;
} tacListNode;

tacListNode head;
tacListNode *curr = &head;
int tempIndex = 0;
int tacIndex = 0;

char *addTacNode(char *op1, char op, char *op2)
{
	tacListNode *temp = (tacListNode *)malloc(sizeof(tacListNode));
	temp->op = op;
	temp->op1 = op1;
	temp->op2 = op2;
	if(-1 == asprintf(&temp->res, "%s%d", "t", tempIndex++))
		fprintf(stderr, "Error concatenating strings");
	temp->tacIndex = tacIndex++;
	temp->next = NULL;
	curr->next = temp;
	curr = temp;
	return temp->res;
}

char *addTacNodeAssignment(char *op1, char *op2)
{
	tacListNode *temp = (tacListNode *)malloc(sizeof(tacListNode));
	temp->op = '\0';
	temp->op2 = NULL;
	temp->op1= op2;
	temp->res = op1;
	temp->tacIndex = tacIndex++;
	temp->next = NULL;
	curr->next = temp;
	curr = temp;
	return temp->res;
}

void printTac()
{
	tacListNode* temp = head.next;
	while(temp!=NULL)
	{
		printf("%s\t=\t%s",temp->res, temp->op1);
		if(temp->op!='\0')
			printf("\t%c\t%s\n", temp->op, temp->op2);
		else
			printf("\n");
		temp = temp->next;
	}
}

tacListNode* search(const char *operand)
{
	if(operand == NULL)
		return NULL;

	char *op = NULL;
	asprintf(&op, "%s", operand);
	tacListNode *temp = head.next;

	while(temp!=NULL && strcmp(temp->res, op)!=0)
		temp = temp->next;

	return temp;
}

void printTriples()
{
	printf("id\top\top1\top2\n");
	tacListNode* temp = head.next;
	while(temp!=NULL)
	{
		printf("(%d)\t", temp->tacIndex);
		if(temp->op != '\0')
			printf("%c", temp->op);

		tacListNode* i1 = search(temp->op1);
		if(i1==NULL)
			printf("\t%s", temp->op1?temp->op1:"");
		else
			printf("\t(%d)", i1->tacIndex);

		tacListNode* i2 = search(temp->op2);
		if(i2==NULL)
			printf("\t%s\n", temp->op2?temp->op2:"");
		else
			printf("\t(%d)\n", i2->tacIndex);

		temp = temp->next;
	}
}

void printIndirectTriples()
{
	printf("pointer\t\t\top\t\t\top1\t\t\top2\n");
	tacListNode* temp = head.next;
	while(temp!=NULL)
	{
		printf("%p\t\t", temp);
		if(temp->op != '\0')
			printf("%c", temp->op);

		printf("\t\t\t");

		tacListNode *i1 = search(temp->op1);
		if(i1==NULL)
			printf("%s\t\t\t", temp->op1?temp->op1:"");
		else
			printf("%p\t\t", i1);

		tacListNode *i2 = search(temp->op2);
		if(i2==NULL)
			printf("%s\n", temp->op2?temp->op2:"");
		else
			printf("%p\n", i2);

		temp = temp->next;
	}
	printf("\nPointer table:\nid\tpointer\n");
	temp = head.next;
	while(temp!=NULL)
	{
		printf("(%d)\t%p\n", temp->tacIndex, temp);
		temp = temp->next;
	}
}

void printQuads()
{
	printf("op\top1\top2\tres\n");
	tacListNode* temp = head.next;
	while(temp!=NULL)
	{
		if(temp->op!='\0')
			printf("%c", temp->op);
		printf("\t%s\t%s\t%s\n", temp->op1, temp->op2?temp->op2:"", temp->res);
		temp = temp->next;
	}
}

yyerror(char *str)
{
	fprintf(stderr, "%s while processing %s\n", str, yytext);
}

void cleanUp(tacListNode* temp)
{
	if(temp->next)
		cleanUp(temp->next);
	free(temp->op1);
	temp->op1 = NULL;
	free(temp->op2);
	temp->op2 = NULL;
	free(temp->res);
	temp->res=NULL;
	free(temp->next);
	temp->next = NULL;
}
%}

%union
{
	int i;
	char *p;
}

%token <p> NUM
%token <p> ID
%type <p> E
%type <p> E1

%left '+' '-'
%left '*' '/'
%left UMINUS

%%
	E2: E1 E2
	  | E1
	  | '\n'
	  | 
	; 
	E1: ID'='E 		{$$=addTacNodeAssignment((char*)$1, (char*)$3);}
	;
	E : E'*'E 		{$$=addTacNode((char*)$1, '*' ,(char*)$3);}
	  | E'/'E 		{$$=addTacNode((char*)$1, '/' ,(char*)$3);}
	  | E'+'E  		{$$=addTacNode((char*)$1, '+' ,(char*)$3);}
	  | E'-'E  		{$$=addTacNode((char*)$1, '-' ,(char*)$3);}
	  | '-'E %prec UMINUS	{$$=addTacNode("", '-', (char *)$2);}
	  | NUM
	  | ID
	;
%%
void main()
{
	head.op1 = head.op2 = NULL;
	head.op = ' ';
	head.next = NULL;
	head.tacIndex = -1;
	yyparse();
	printf("-------------------------------------------------------------------------------------------\n");
	printf("Printing 3AC\n");
	printf("-------------------------------------------------------------------------------------------\n");
	printTac();
	printf("-------------------------------------------------------------------------------------------\n");
	printf("Printing triples format\n");
	printf("-------------------------------------------------------------------------------------------\n");
	printTriples();
	printf("-------------------------------------------------------------------------------------------\n");
	printf("Printing indirect triples format\n");
	printf("-------------------------------------------------------------------------------------------\n");
	printIndirectTriples();
	printf("-------------------------------------------------------------------------------------------\n");
	printf("Printing quadruples format\n");
	printf("-------------------------------------------------------------------------------------------\n");
	printQuads();
	cleanUp(&head);
}
