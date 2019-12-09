%{
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include "y.tab.h"
%}
%%
[ \t]											{}
[\n]											{return NEWLINE;}
[-]?[0-9]+ 									    {asprintf(&yylval.p, "%s", yytext);return ID;}
(_[a-zA-Z0-9]|[a-zA-Z])(_|[a-zA-Z0-9])* 		{asprintf(&yylval.p, "%s", yytext);return ID;}
.												{return yytext[0];}
%%

int yywrap()
{
	return 1;
}

