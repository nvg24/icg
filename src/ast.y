%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lex.yy.c"

#define TAC 1
#define POSTFIX 2
#define AST 3
#define DAG 4

int currIdx;

int yyerror(char *err)
{
	return 1;
}

typedef struct astNode_impl
{
	char op;
	char *id;
	int nodeIdx;
	struct astNode_impl* left;
	struct astNode_impl* right;
} astNode;

astNode *mknode(char op, astNode* op1, astNode *op2)
{
	astNode* temp = (astNode *) malloc(sizeof(astNode));
	temp->op = op;
	temp->id = NULL;
	temp->left=op1;
	temp->right=op2;
	return temp;
}

astNode *mkleaf(char *id)
{
	astNode* temp = (astNode *) malloc(sizeof(astNode));
	temp->op = '\0';
	temp->id = strdup(id);
	temp->left= NULL;
	temp->right=NULL;
	return temp;
}

astNode *process(char op, astNode* op1, astNode *op2, char *id)
{
	astNode *temp = NULL;
	if(op!='\0' && id==NULL)
		temp = mknode(op, op1, op2);
	else
		temp = mkleaf(id);
//	printf("\n%p\t%c,%p,%p,%s",temp,temp->op,temp->left,temp->right,temp->id);
	temp->nodeIdx=currIdx++;
	if(temp->id)
		printf("p%d\t%s\t",temp->nodeIdx,temp->id);
	else
		printf("p%d\t%c\t",temp->nodeIdx,temp->op);

	if(temp->left)
		printf("p%d\t",temp->left->nodeIdx);
	else
		printf("NULL\t");

	if(temp->right)
		printf("p%d\n",temp->right->nodeIdx);
	else
		printf("NULL\n");

	return temp;
}

void printInorder(astNode* root)
{
	if(root==NULL)
		return;

	printInorder(root->left);
	if(root->id != NULL)
		printf("%s", root->id);
	else
		printf("%c", root->op);
	printInorder(root->right);
	return;
}

void printPreorder(astNode* root)
{
	if(root==NULL)
		return;

	if(root->id != NULL)
		printf("%s", root->id);
	else
		printf("%c", root->op);
	printPreorder(root->left);
	printPreorder(root->right);
	return;
}

void printPostorder(astNode* root)
{
	if(root==NULL)
		return;

	printPostorder(root->left);
	printPostorder(root->right);
	if(root->id != NULL)
		printf("%s", root->id);
	else
		printf("%c", root->op);
	return;
}

void cleanup(astNode* root)
{
	if(root==NULL)
		return;
	cleanup(root->left);
	cleanup(root->right);
	if(root->id)
		free(root->id);
}
%}

%union
{
	struct astNode_impl *node;
	char *p;
}

%token <p> NUM
%token <p> ID
%token <p> NEWLINE
%type <node> E
%type <node> E1
%type <node> B

%left '+' '-'
%left '*' '/'
%left UMINUS

%%
	E2: E1 NEWLINE E2
	  | E1
	  | 
	; 
	E1: ID'='E 					{
									$$=process('=', process('\0', NULL, NULL, (char *)$1), (astNode *)$3, NULL);
									printf("\nPrinting Inorder\n");
									printInorder((astNode *)$$);
									printf("\n\nPrinting Preorder\n");
									printPreorder((astNode *)$$);
									printf("\n\nPrinting Postorder\n");
									printPostorder((astNode *)$$);
									printf("\n");
									cleanup((astNode *)$$);
								}
	;
	E : E'*'E 					{$$=process('*',(astNode *) $1, (astNode *)$3, NULL);}
	  | E'/'E 					{$$=process('/', (astNode *)$1, (astNode *)$3, NULL);}
	  | E'+'E  					{$$=process('+', (astNode *)$1, (astNode *)$3, NULL);}
	  | E'-'E  					{$$=process('-', (astNode *)$1, (astNode *)$3, NULL);}
	  | '-'E %prec UMINUS		{$$=process('-', NULL, (astNode *)$2, NULL);}
	  | B
	  | NUM						{$$=process('\0', NULL, NULL, (char *)$1);}
	  | ID						{$$=process('\0', NULL, NULL, (char *)$1);}
	;

	B : '('E'*'E')' 			{$$=process('*',(astNode *) $2, (astNode *)$4, NULL);}
	  | '('E'/'E')'				{$$=process('/',(astNode *) $2, (astNode *)$4, NULL);}
	  | '('E'+'E')'  			{$$=process('+',(astNode *) $2, (astNode *)$4, NULL);}
	  | '('E'-'E')'  			{$$=process('-',(astNode *) $2, (astNode *)$4, NULL);}
	  | '(''-'E')' %prec UMINUS	{$$=process('-', NULL, (astNode *)$3, NULL);}
	  | '('NUM')'				{$$=process('\0', NULL, NULL, (char *)$2);}
	  | '('ID')'				{$$=process('\0', NULL, NULL, (char *)$2);}
	  ;
%%
void main(int argc, char **argv)
{
	currIdx = 0;
	printf("Ptr\tData\tleftPtr\trightPtr\n");
	yyparse();
}


