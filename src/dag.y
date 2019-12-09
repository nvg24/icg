%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lex.yy.c"
#include "hash.c"

#define TAC 1
#define POSTFIX 2
#define AST 3
#define DAG 4

int mode;
int currIdx;

hashtable_t *h;

char *strrev(char *str)
{
      char *p1, *p2;

      if (! str || ! *str)
            return str;
      for (p1 = str, p2 = str + strlen(str) - 1; p2 > p1; ++p1, --p2)
      {
            *p1 ^= *p2;
            *p2 ^= *p1;
            *p1 ^= *p2;
      }
      return str;
}

int yyerror(char *err)
{
	return 1;
}

astNode *mknode(char op, astNode* op1, astNode *op2, int inBracket)
{
	astNode* temp = (astNode *) malloc(sizeof(astNode));
	if(temp==NULL)
		printf("OOM at %d\n", __LINE__);
	temp->str = NULL;
	asprintf(&temp->str,"%s%s%c%s%s", inBracket?"(":"" , op1?op1->str:"", op, op2->str, inBracket?")":"");
	if(temp->str==NULL)
		printf("OOM at %d\n", __LINE__);
	temp->op = op;
	temp->id = NULL;
	temp->left=op1;
	temp->right=op2;
	return temp;
}

astNode *mkleaf(char *id)
{
	astNode* temp = (astNode *) malloc(sizeof(astNode));
	if(temp==NULL)
		printf("OOM at %d\n", __LINE__);
	temp->op = '\0';
	temp->id = strdup(id);
	if(temp->id==NULL)
		printf("OOM at %d\n", __LINE__);
	temp->str = temp->id;
	temp->left= NULL;
	temp->right=NULL;
	return temp;
}

astNode *process(char op, astNode* op1, astNode *op2, char *id, int inBracket)
{
	astNode *temp = NULL;
	if(mode == DAG)
	{
		char *key = NULL;
		if(op == '\0')
			key = strdup(id);
		else
			asprintf(&key,"%s%s%c%s%s",inBracket?"(":"", op1?op1->str:"", op, op2->str,inBracket?")":"");
		if(key==NULL)
			printf("OOM at %d\n", __LINE__);
		temp = ht_get(h, key);
		free(key);
		key = NULL;
		if(temp)
		{
			//printf("node:%p node->str:%s\n", temp, temp->str);
			return temp;
		}
	}
	if(op!='\0' && id==NULL)
		temp = mknode(op, op1, op2, inBracket);
	else
		temp = mkleaf(id);
	if(mode == DAG)
	{
		char *key = strdup(temp->str);
		if(key==NULL)
			printf("OOM at %d\n", __LINE__);
		ht_set(h, key, temp);
		if(op=='+' || op=='*')
		{
			char *revkey = strrev(key);
			if(revkey[0] == ')' && revkey[strlen(key)-1] == '(')
			{
				revkey[0] = '(';
				revkey[strlen(revkey)-1]=')';
			}
			ht_set(h, revkey, temp);
			free(key);
			key = NULL;
		}
	}
	//printf("node:%p node->str:%s\n", temp, temp->str);
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

void print(astNode* root)
{
	if(root==NULL)
		return;

	print(root->left);
	if(root->id != NULL)
		printf("%s", root->id);
	else
		printf("%c", root->op);
	//printf(" %p %s ", root, root->str);
	print(root->right);
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
	E1: ID'='E 				{
								astNode *temp = process('\0', NULL, NULL, (char *)$1,0);
								$$ = process('=', temp, (astNode *)$3, NULL,0);
								//print((astNode *)($$));
								//printf("Node :%p string:%s\n", $$, $$->str);
								//cleanup((astNode *)$$);
							}
	;
	E : E'*'E 				{$$=process('*',(astNode *) $1, (astNode *)$3, NULL,0);}
	  | E'/'E 				{$$=process('/', (astNode *)$1, (astNode *)$3, NULL,0);}
	  | E'+'E  				{$$=process('+', (astNode *)$1, (astNode *)$3, NULL,0);}
	  | E'-'E  				{$$=process('-', (astNode *)$1, (astNode *)$3, NULL,0);}
	  | '-'E %prec UMINUS	{$$=process('-', NULL, (astNode *)$2, NULL,0);}
	  | B
	  | NUM					{$$=process('\0', NULL, NULL, (char *)$1,0);}
	  | ID					{$$=process('\0', NULL, NULL, (char *)$1,0);}
	;
	
	B : '('E'*'E')' 		{$$=process('*',(astNode *) $2, (astNode *)$4, NULL,1);}
	  | '('E'/'E')'			{$$=process('/',(astNode *) $2, (astNode *)$4, NULL,1);}
	  | '('E'+'E')'  		{$$=process('+',(astNode *) $2, (astNode *)$4, NULL,1);}
	  | '('E'-'E')'  		{$$=process('-',(astNode *) $2, (astNode *)$4, NULL,1);}
	  | '(''-'E')' %prec UMINUS	{$$=process('-', NULL, (astNode *)$3, NULL,1);}
	  | '('NUM')'			{$$=process('\0', NULL, NULL, (char *)$2,1);}
	  | '('ID')'			{$$=process('\0', NULL, NULL, (char *)$2,1);}
	  ;	
%%
void main(int argc, char **argv)
{
	currIdx=0;
	mode = DAG;
	h = ht_create( 65536 );
	printf("Ptr\tData\tleftPtr\trightPtr\n");
	yyparse();
}


