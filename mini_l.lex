%{
	#include "y.tab.h"
	extern "C" int yylex();

	static int next_column = 1;
	int column = 1;

	#define HANDLE_COLUMN column = next_column; next_column += strlen(yytext)  
%}

%option noyywrap noinput nounput yylineno

DIGIT [0-9]
LETTER [a-zA-Z]
ALPHANUM [a-zA-Z0-9]
ID {LETTER}(({ALPHANUM}|_)*{ALPHANUM})*
INVALIDID ^{LETTER}{ID}|{ID}_

%%
"function"	{HANDLE_COLUMN; return FUNCTION; }
"beginparams"	{HANDLE_COLUMN; return BEGIN_PARAMS; }
"endparams"	{HANDLE_COLUMN; return END_PARAMS; }
"beginlocals"	{HANDLE_COLUMN; return BEGIN_LOCALS; }
"endlocals"	{HANDLE_COLUMN; return END_LOCALS; }
"beginbody"	{HANDLE_COLUMN; return BEGIN_BODY; }
"endbody"	{HANDLE_COLUMN; return END_BODY; }
"integer"	{HANDLE_COLUMN; return INTEGER; }
"array"		{HANDLE_COLUMN; return ARRAY; }
"of"		{HANDLE_COLUMN; return OF; }
"if"		{HANDLE_COLUMN; return IF; }
"then"		{HANDLE_COLUMN; return THEN; }
"endif"		{HANDLE_COLUMN; return ENDIF; }
"else"		{HANDLE_COLUMN; return ELSE; }
"while"		{HANDLE_COLUMN; return WHILE; }
"do"		{HANDLE_COLUMN; return DO; }
"foreach"	{HANDLE_COLUMN; return FOREACH; }
"in"		{HANDLE_COLUMN; return IN; }
"beginloop"	{HANDLE_COLUMN; return BEGINLOOP; }
"endloop"	{HANDLE_COLUMN; return ENDLOOP; }
"continue"	{HANDLE_COLUMN; return CONTINUE; }
"read"		{HANDLE_COLUMN; return READ; }
"write"		{HANDLE_COLUMN; return WRITE; }
"and"		{HANDLE_COLUMN; return AND; } 
"or"		{HANDLE_COLUMN; return OR; }
"not"		{HANDLE_COLUMN; return NOT; }
"true"		{HANDLE_COLUMN; return TRUE; }
"false"		{HANDLE_COLUMN; return FALSE; }
"return"	{HANDLE_COLUMN; return RETURN; }
"note"		{HANDLE_COLUMN; return COMMENT; }
"endnote"	{HANDLE_COLUMN; return END_COMMENT; }

"-"		{HANDLE_COLUMN; return SUB; }
"+"		{HANDLE_COLUMN; return ADD; }
"*"		{HANDLE_COLUMN; return MULT; }
"/"		{HANDLE_COLUMN; return DIV; }
"%"		{HANDLE_COLUMN; return MOD; }

"=="		{HANDLE_COLUMN; return EQ; }
"!="		{HANDLE_COLUMN; return NEQ; }
"<"		{HANDLE_COLUMN; return LT; }
">"		{HANDLE_COLUMN; return GT; }
"<="		{HANDLE_COLUMN; return LTE; }
">="		{HANDLE_COLUMN; return GTE; }

{ID}            {HANDLE_COLUMN; yylval.string = strdup(yytext); return IDENTIFIER; }
{DIGIT}+        {HANDLE_COLUMN; yylval.string = strdup(yytext);  return NUMBER; }

";"		{HANDLE_COLUMN; return SEMICOLON; }
":"		{HANDLE_COLUMN; return COLON; }
","		{HANDLE_COLUMN; return COMMA; }
"("		{HANDLE_COLUMN; return L_PAREN; }
")"		{HANDLE_COLUMN; return R_PAREN; }
"["		{HANDLE_COLUMN; return L_SQUARE_BRACKET; }
"]"		{HANDLE_COLUMN; return R_SQUARE_BRACKET; }
":="		{HANDLE_COLUMN; return ASSIGN; }

[ \t]+		{HANDLE_COLUMN; /* ignore whitespace */ }
"\n"		{HANDLE_COLUMN; next_column = 1; }
"##"		{HANDLE_COLUMN; }

{INVALIDID}	{HANDLE_COLUMN; }
.		{HANDLE_COLUMN; }

%%
