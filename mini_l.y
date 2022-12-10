%{
    #include <stdio.h>
    #include <typeinfo>
    #include <iostream>
    #include <string>
    #include <cstring>
    #include <vector>
    #include <algorithm>
    #include <cassert>
    #include <sstream>

    #define YYERROR_VERBOSE 1

    #define SSTR( x ) static_cast< std::ostringstream & >( \
        ( std::ostringstream() << std::dec << x ) ).str()

    using namespace std;
	
    extern int yylineno;
    extern int column;

    extern "C" int yylex();
    extern int yyleng;
    extern char *yytext;

    extern FILE *yyin;

    bool errorFlag = false;
    void yyerror(const char *s)
    {
        fprintf(stderr,"error: %s in line %d, column %d\n", s, yylineno, column);
	errorFlag = true;
    }

    vector<const char*> identTable; //table to store non-array identifiers

    vector<const char*> arrIdentTable; // table to store array identifiers
    vector<int> arrSizeTable; // table to store array sizes

    vector<const char*> funcTable; // table to store function identifiers
    vector< vector<const char*> > paramTable; // table to store paramlist relative to each function (parallel to funcTable)
    
    vector<const char*> tempTable; // table to store temp names
    vector<int> ifTable;
    int ifCounter = -1;
    vector<int> loopTable;
    int loopCounter = -1;

   void handleAccessArray(const char *name, const char *index) {
   bool undefinedVar = true;
   
   for(int i = 0; i < arrIdentTable.size(); i++){
     if(strcmp(arrIdentTable.at(i), name) == 0){
       undefinedVar = false;
       // if array name is valid, check for index in bounds
       if(atoi(index) < 0 || atoi(index) >= arrSizeTable.at(i)) {
        string errorMessage = "Index out of bounds for array: ";
        errorMessage += name;
        errorMessage += ".";
        yyerror(errorMessage.c_str());
        errorMessage = "Array size: ";
        errorMessage += SSTR(arrSizeTable.at(i));
        errorMessage += ", Index used to access: ";
        errorMessage += index;
        errorMessage += ".";
        yyerror(errorMessage.c_str());
       }
     }
   }
   if(undefinedVar){
     string errorMessage = "Undeclared array: ";
     errorMessage += name;
     errorMessage += ".";
     yyerror(errorMessage.c_str());
   }
   }

   void handleNewFunction(const char *name) {
    // first, check for duplicate declaration
    bool duplicate = false;
    for (int i = 0; i < funcTable.size(); i++) {
     if(strcmp(funcTable.at(i), name) == 0) {
      duplicate = true;
     }
     if (duplicate) {
      string errorMessage = "Duplicate declaration of function identifier: ";
      errorMessage += funcTable.at(i); 
      yyerror(errorMessage.c_str());
      break;
     }
    }

    funcTable.push_back(name);
   }

   vector<const char*> delimitDeclarations(char *input) { // input is declarations, removes garbage, delimits by \n
    char *dest = input;
    char *src  = input;
    while(*src) { // this loop removes "." and " "
     if(*src == '.' || *src == ' ') { src++; continue;}
      *dest++ = *src++;
    }
    *dest = '\0';
    
 
    string str = "";
    str += strdup(input);
  
    stringstream ss(str);
    string token;
    
    vector<const char*> declarations;
    while(getline(ss, token, '\n')) {
     declarations.push_back(strdup(token.c_str()));
    }
    
    return declarations;
   }
    
%}

%code requires {
    struct CodeNode {
        const char *code;
        const char *name;
    };
}

%union {
    char *string;
    CodeNode *node;
}

/* reserved words */
%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY
%token INTEGER
%token ARRAY
%token OF
%token IF THEN ENDIF ELSE
%token WHILE DO
%token FOREACH IN
%token BEGINLOOP ENDLOOP
%token CONTINUE
%token READ WRITE
%token AND OR NOT
%token TRUE FALSE
%token RETURN
%token COMMENT END_COMMENT

/*arithmetic operators*/
%token SUB ADD MULT DIV MOD

/*comparison operators*/
%token EQ NEQ LT GT LTE GTE

/*identifiers and numbers*/
%token <string> IDENTIFIER 
%token <string> NUMBER

/*other special symbols*/
%token SEMICOLON COLON COMMA
%token L_PAREN R_PAREN
%token L_SQUARE_BRACKET R_SQUARE_BRACKET
%token ASSIGN
%token EOL

/* filler token to server as a TODO */
%token TODO

%type <node> program functions
%type <node> parameters declarations statements returnStmt
%type <node> statement
%type <node> id
%type <node> exp factor term condition stmt_if stmt_while

%%


program:
 functions
 {
   bool mainFound = false;
   for (int i = 0; i < funcTable.size(); i++) {
     if (strcmp(funcTable.at(i), "main") == 0) mainFound = true;
   }
   if (!mainFound) {
     string errorMessage = "No main function";
     yyerror(errorMessage.c_str());
   }
   if (!errorFlag) printf("%s",$1->code);
 }
 ;

functions:
 FUNCTION id BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY functions {
  handleNewFunction($2->name);

  string functionsCode = $12->code;
  string statements_code = $10->code;
  string localvar_code = $7->code;
  string param_code = $4->code;
  string func_name = $2->name;

  vector<const char*> declarations = delimitDeclarations((char*)strdup($4->code));
  
  for (int i = 0; i < declarations.size(); i++) {
   param_code += "= ";
   param_code += declarations.at(i);
   param_code += ", $";
   param_code += SSTR(i);
   param_code += "\n";
  }

  string pre_syntax = "func ";
  pre_syntax += func_name;
  pre_syntax += "\n";
  string post_syntax = "endfunc\n";
  string syntax = pre_syntax + param_code + localvar_code + statements_code + post_syntax + "\n" + functionsCode;
  CodeNode *node = new CodeNode;
  $$ = node;
  $$->name = strdup("");
  $$->code = strdup(syntax.c_str());
 }
 |
 FUNCTION id BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {
  handleNewFunction($2->name);
  
  string statements_code = $10->code;
  string localvar_code = $7->code;
  string param_code = $4->code;
  string func_name = $2->name;

  vector<const char*> declarations = delimitDeclarations((char*)strdup($4->code));
  for (int i = 0; i < declarations.size(); i++) {
   param_code += "= ";
   param_code += declarations.at(i);
   param_code += ", $";
   param_code += SSTR(i);
   param_code += "\n";
  }

  string pre_syntax = "func ";
  pre_syntax += func_name;
  pre_syntax += "\n";
  string post_syntax = "endfunc\n";
  string syntax = pre_syntax + param_code + localvar_code + statements_code + post_syntax;
  CodeNode *node = new CodeNode;
  $$ = node;
  $$->name = strdup("");
  $$->code = strdup(syntax.c_str());
 }
 ;

returnStmt:
 RETURN exp
 {
   string src = $2->name;
   string expCode = "";
   CodeNode *node = new CodeNode;
	
	
   string codeCheck = $2->code;
   if(codeCheck != ""){
     expCode += $2->code;
     //expCode += "\n";
   }

   string syntax = expCode;
   syntax += "ret ";
   syntax += src;
   syntax += "\n";
   $$->code = strdup(syntax.c_str());
   $$->name = strdup(src.c_str());
 }
 ;

parameters:
 INTEGER id COMMA parameters 
 {
   string postSyntax = $4->code;
   CodeNode *node = new CodeNode; 
   string preSyntax = "param ";
   preSyntax += $2->name;
   preSyntax += "\n";
   string syntax = preSyntax + postSyntax;
   node->code = syntax.c_str();
   //$$ = node;
   $$->code = strdup(syntax.c_str());
 }
 | INTEGER id 
 {
   CodeNode *node = new CodeNode;
   string syntax = "param ";
   syntax += $2->name;
   syntax += "\n";
   node->code = syntax.c_str();
   //$$ = node;
   $$->code = strdup(syntax.c_str());
 }
 | exp {
  string syntax =  $1->code;
  syntax += "param ";
  syntax += $1->name;
  syntax += "\n";

  CodeNode *node = new CodeNode;
  $$ = node;
  $$->name = strdup($1->name);
  $$->code = strdup(syntax.c_str());
 };

declarations:
 {
  CodeNode *node = new CodeNode;
  $$ = node;
  node->name = "";
  node->code = "";
 }
 |
 INTEGER id COMMA declarations
 {
   // check for duplicate names
   // TODO: check with TA/prof if names can overlap between functions/arrays/single vars 
   for(int i = 0; i < identTable.size(); i++){
     if(strcmp(identTable.at(i), $2->name) == 0){
       string errorMessage = "Duplicate declaration ";
       errorMessage += identTable.at(i);
       yyerror(errorMessage.c_str());
     }
   }
   identTable.push_back($2->name);
   string postSyntax = $4->code;
   CodeNode *node = new CodeNode;
   string preSyntax = ". ";
   preSyntax += $2->name;
   preSyntax += "\n";
   string syntax = preSyntax + postSyntax;
   node->code = syntax.c_str();
   //$$ = node; 
   $$->code = strdup(syntax.c_str());
 }
 | INTEGER id { 
    for(int i = 0; i < identTable.size(); i++){
     if(strcmp(identTable.at(i), $2->name) == 0){
      string errorMessage = "Duplicate declaration of var identifier: ";
      errorMessage += identTable.at(i);
      yyerror(errorMessage.c_str());
     }
    }
    identTable.push_back($2->name);
    
    CodeNode *node = new CodeNode;
    string syntax = ". ";
    syntax += $2->name;
    syntax += "\n";
    node->code = syntax.c_str();
    //$$ = node;
    $$->code = strdup(syntax.c_str());
 }
 | INTEGER ARRAY id L_SQUARE_BRACKET exp R_SQUARE_BRACKET {
   for(int i = 0; i < arrIdentTable.size(); i++){
     if(strcmp(arrIdentTable.at(i), $3->name) == 0){
      string errorMessage = "Duplicate declaration of array identifier: ";
      errorMessage += arrIdentTable.at(i);
      yyerror(errorMessage.c_str());
     }
    }

    arrIdentTable.push_back($3->name);
    //arrSizeTable.push_back(atoi($5));

    CodeNode *node = new CodeNode;
	//delete if disaster
	string tempCheck = $5->code;
   string expCode = "";
   if(tempCheck != ""){
     expCode += $5->code;
     //expCode += "\n";
   }

	string syntax = expCode;
    syntax += ".[] ";
    syntax += $3->name;
    syntax += ", ";
    syntax += $5->name;
    syntax += "\n";

    $$ = node;
    $$->code = strdup(syntax.c_str());  
 }
 | INTEGER ARRAY id L_SQUARE_BRACKET exp R_SQUARE_BRACKET COMMA declarations {
   for(int i = 0; i < arrIdentTable.size(); i++){
     if(strcmp(arrIdentTable.at(i), $3->name) == 0){
      string errorMessage = "Duplicate declaration of array identifier: ";
      errorMessage += arrIdentTable.at(i);
      yyerror(errorMessage.c_str());
     }
    }
    arrIdentTable.push_back($3->name);
    //arrSizeTable.push_back(atoi($5));

	
	string expCode = $5->code;
	string syntax = expCode;
   syntax += ".[] ";
    syntax += $3->name;
    syntax += ", ";
    syntax += $5->name;
    syntax += "\n";
    syntax += $8->code;
    
    CodeNode *node = new CodeNode;
    $$ = node;
    $$->code = strdup(syntax.c_str());
 }
 ;

id:
 IDENTIFIER
 {
  CodeNode *node = new CodeNode;
  node->code = "";
  node->name = $1;
  $$ = node;
  $$->name = strdup($1);
  $$->code = "";
 }
 ;

statements: 
 statement SEMICOLON statements
 { 
   string postSyntax = $3->code;
   string preSyntax = $1->code;
   string syntax = preSyntax + postSyntax;
   CodeNode *node = new CodeNode;
   node->code = syntax.c_str();
   //$$ = node;
   $$->code = strdup(syntax.c_str()); 
 }
 | statement SEMICOLON
 {
   string statementCode = $1->code;
   CodeNode *node = new CodeNode;
   node->code = statementCode.c_str();
   //$$ = node;
   $$->code = strdup(statementCode.c_str());
 }
 ;

statement:
 id ASSIGN exp
 {
   // check if variable has been declared
   bool undefinedVar = true;
   for(int i = 0; i < identTable.size(); i++){
     if(strcmp(identTable.at(i), $1->name) == 0){
       undefinedVar = false;
     }
   }
   if(undefinedVar){
     string errorMessage = "Undeclared variable: ";
     errorMessage += $1->name;
     yyerror(errorMessage.c_str());
   }
   string tempCheck = $3->code;
   string expCode = "";
   if(tempCheck != ""){
     expCode += $3->code;
     //expCode += "\n";
   }
   string preSyntax = "= ";
   string midSyntax = ", ";
   string dest = $1->name;
   string src = $3->name;
   string syntax = expCode + preSyntax + dest + midSyntax + src + "\n";
   CodeNode *node = new CodeNode;
   node->code = syntax.c_str();
   $$->code = strdup(syntax.c_str());
   //$$ = node;
 }
 | id L_SQUARE_BRACKET exp R_SQUARE_BRACKET ASSIGN exp {
   // check if array exists/duplicates and check if index in bounds
   //handleAccessArray($1->name, $3);
   // construct syntax
   string tempCheck = $6->code;
   string expCode = "";
	string expCode_1 = $3->code;
	
   if(tempCheck != ""){
     expCode += $6->code;
     //expCode += "\n";
   }

   string syntax = expCode;
	syntax += expCode_1;

   syntax += "[]= ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;
   syntax += ", ";
   syntax += $6->name;
   syntax += "\n";

   CodeNode *node = new CodeNode;
   $$ = node;
   $$-> code = strdup(syntax.c_str());
 } 
 | stmt_if
 { 
   string ifCode = $1->code;
   string ifName = $1->name;
   $$->code = strdup(ifCode.c_str());
   $$->name = strdup(ifName.c_str());
 }
 | stmt_while
 { 
	string whileCode = $1->code;
	string whileName = $1->name;
	$$->code = strdup(whileCode.c_str());
	$$->name = strdup(whileName.c_str());
 }
 | READ COLON id
 { 
   bool undefinedVar = true;
   for(int i = 0; i < identTable.size(); i++){
     if(strcmp(identTable.at(i), $3->name) == 0){
       undefinedVar = false;
     }
   }
   if(undefinedVar){
     string errorMessage = "Undefined variable ";
     errorMessage += $3->name;
     yyerror(errorMessage.c_str());
   }
   string syntax = ".< ";
   syntax += $3->name;
   syntax += "\n";
   CodeNode *node = new CodeNode;
   node->code = syntax.c_str();
   //$$ = node;
   $$->code = strdup(syntax.c_str());
 }
 | READ COLON id L_SQUARE_BRACKET exp R_SQUARE_BRACKET { 
   //handleAccessArray($3->name, $5);
   
	string expCode = $5->code;
	string syntax = expCode;
   syntax += ".[]< ";
   syntax += $3->name;
   syntax += ", ";
   syntax += $5->name;
   syntax += "\n";

   CodeNode *node = new CodeNode;
   $$ = node;
   $$->code = strdup(syntax.c_str());
 }
 | WRITE COLON id
 { 
   bool undefinedVar = true;
   for(int i = 0; i < identTable.size(); i++){
     if(strcmp(identTable.at(i), $3->name) == 0){
       undefinedVar = false;
     }
   }
   if(undefinedVar){
     string errorMessage = "Undefined variable ";
     errorMessage += $3->name;
     yyerror(errorMessage.c_str());
   }
   CodeNode *node = new CodeNode;
   string syntax = ".> ";
   syntax += $3->name;
   syntax += "\n";
   node->code = syntax.c_str();
   //$$ = node;
   $$->code = strdup(syntax.c_str());
 }
 | WRITE COLON id L_SQUARE_BRACKET exp R_SQUARE_BRACKET {
   //handleAccessArray($3->name, $5);
   
	string expCode = $5->code;
	string syntax = expCode;
   syntax += ".[]> ";
   syntax += $3->name;
   syntax += ", ";
   syntax += $5->name;
   syntax += "\n";

   CodeNode *node = new CodeNode;
   $$ = node;
   $$->code = strdup(syntax.c_str());
 } 
 | returnStmt {
   CodeNode *node = new CodeNode;
   $$ = node;
   $$->name = strdup($1->name);
   $$->code = strdup($1->code);
 }
 ;

stmt_if:
 if L_PAREN condition R_PAREN THEN statements ENDIF
 {

	string ifNum = SSTR(ifTable.back());

   string conditionCode = $3->code;
   string conditionName = $3->name;

   string ifCode = "";

   string codeCheck = $3->code;
   if(codeCheck != ""){
     ifCode += $3->code;
     ifCode += "\n";
   }

   string ifName = "";

   string ifTrue = "if_true";
   ifTrue += ifNum.c_str();

   ifCode += "?:= ";
   ifCode += ifTrue;
   ifCode += ", ";
   ifCode += conditionName;
   ifCode += "\n";

	string endIf = "endif";
	endIf += ifNum.c_str();
	ifCode += ":= ";
	ifCode += endIf;
	ifCode += "\n";
   
   ifCode += ": ";
   ifCode += ifTrue;
   ifCode += "\n";
   string statementsCode = $6->code;
   ifCode += statementsCode;

   ifCode += ": ";
   ifCode += endIf;
   ifCode += "\n";
	
   
   ifTable.pop_back();

   $$->code = strdup(ifCode.c_str());
   $$->name = strdup(ifName.c_str());

 }
 | if L_PAREN condition R_PAREN THEN statements ELSE statements ENDIF
 {
	string ifNum = SSTR(ifTable.back());
   string conditionCode = $3->code;
   string conditionName = $3->name;
	
   string ifCode = "";
   string codeCheck = $3->code;
   if(codeCheck != ""){
     ifCode += $3->code;
     ifCode += "\n";
   }

   string ifName = "";

   string ifTrue = "if_true";
   ifTrue += ifNum.c_str();

   ifCode += "?:= ";
   ifCode += ifTrue;
   ifCode += ", ";
   ifCode += conditionName;
   ifCode += "\n";
   
	ifCode += ":= ";
	string elseCode = "else";
	elseCode += ifNum.c_str();
	ifCode += elseCode;
	ifCode += "\n";

   ifCode += ": ";
   ifCode += ifTrue;
   ifCode += "\n";

   string statementsCode = $6->code;
   ifCode += statementsCode;

	string endIf = "endif";
	endIf += ifNum.c_str();
	ifCode += ":= ";
	ifCode += endIf;
	ifCode += "\n";

	ifCode += ": ";
	ifCode += elseCode;
	ifCode += "\n";
	
	statementsCode = 	$8->code;
	ifCode += statementsCode;

	ifCode += ": ";
   ifCode += endIf;
   ifCode += "\n";
   
   ifTable.pop_back();

   $$->code = strdup(ifCode.c_str());
   $$->name = strdup(ifName.c_str());

 
 }

;

stmt_while: 
 while L_PAREN condition R_PAREN BEGIN_BODY statements END_BODY
 { 
	string loopNum = SSTR(loopTable.back());
	string whileName = "";
	string conditionCode = $3->code;
	string conditionName = $3->name;

	string whileCode = ": ";
	string beginLoop = "beginLoop";
	beginLoop += loopNum.c_str();
	whileCode += beginLoop;
	whileCode += "\n";
	
	whileCode += conditionCode;
	whileCode += "\n";

	whileCode += "?:= ";
	string loopBody = "loopBody";
	loopBody += loopNum.c_str();
	whileCode += loopBody;
	whileCode += ", ";
	whileCode += conditionName;
	whileCode += "\n";

	whileCode += ":= ";
	string endLoop = "endLoop";
	endLoop += loopNum.c_str();
	whileCode += endLoop;
	whileCode += "\n";

	whileCode += ": ";
	whileCode += loopBody;
	whileCode += "\n";
		
	string statementsCode = $6->code;
	whileCode += statementsCode;

	whileCode += ":= ";
	whileCode += beginLoop;
	whileCode += "\n";
	
	whileCode += ": ";
	whileCode += endLoop;
	whileCode += "\n";

	$$->code = strdup(whileCode.c_str());
	$$->name = strdup(whileName.c_str());
	
	loopTable.pop_back();	
	
		
 }
 | while BEGIN_BODY statements END_BODY WHILE L_PAREN condition R_PAREN
 { 
	string loopNum = SSTR(loopTable.back());
	string whileName = "";
	string conditionCode = $7->code;
	string conditionName = $7->name;

	string whileCode = ": ";
	string loopBody = "loopbody";
	loopBody += loopNum.c_str();
	whileCode += loopBody;
	whileCode += "\n";

	string statementCode = $3->code;
	whileCode += statementCode;

	whileCode += conditionCode;
	whileCode += "\n";

	whileCode += "?:= ";
	whileCode += loopBody;
	whileCode += ", ";
	whileCode += conditionName;
	whileCode += "\n";
	
	$$->code = strdup(whileCode.c_str());
	$$->name = strdup(whileName.c_str());
	
	loopTable.pop_back();	
	
 }
 ;

if:
 IF
{
  ifCounter++;

  ifTable.push_back(ifCounter);

}

while:
	WHILE {
	loopCounter++;
	loopTable.push_back(loopCounter);
}
| DO {

	loopCounter++;
	loopTable.push_back(loopCounter);
}
condition: 
 exp EQ exp 
 { 
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     //syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     //syntax += "\n";
   }
   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += "== ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);
 }
 | exp NEQ exp 
 { 
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     //syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     //syntax += "\n";
   }
   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += "!= ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);
 }  
 | exp LT exp 
 { 
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     //syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     //syntax += "\n";
   }
   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += "< ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);
 }  
 | exp GT exp 
 { 
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     //syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     //syntax += "\n";
   }
   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += "> ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);
 }  
 | exp LTE exp 
 { 
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     syntax += "\n";
   }
   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += "<= ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);
 }  
 | exp GTE exp 
 { 
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     syntax += "\n";
   }
   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += ">= ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);
 }
 | exp 
 {
   // initailizing CodeNode to check for strange behavior
   CodeNode *node = new CodeNode;
   $$ = node;
   $$->code = strdup($1->code);
   $$->name = strdup($1->name);
 }
 ;

exp: 
 factor 
 {
   CodeNode *node = new CodeNode;
   $$ = node;
   $$->name = strdup($1->name);
   $$->code = strdup($1->code);
 }      
 | exp ADD factor 
 {
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());
   
   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     //syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     //syntax += "\n";
   }
   
	// HOTFIX

   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += "+ ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;
   syntax += "\n";
 
   CodeNode *node = new CodeNode;
   $$ = node;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name); 
 }
 | exp SUB factor 
 {
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     //syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     //syntax += "\n";
   }

        // HOTFIX
   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += "- ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;
   syntax += "\n";

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);  
 }
 ;

factor: 
 term 
 {
   CodeNode *node = new CodeNode;
   $$ = node;
   $$->name = strdup($1->name);
   $$->code = strdup($1->code);
 }     
 | factor MULT term 
 { 
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     syntax += "\n";
   }
   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += "* ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;
   syntax += "\n";

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);
 }
 | factor DIV term 
 {
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $1->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax += $1->code;
     syntax += "\n";
   }
   codeCheck = $3->code;
   if(codeCheck != ""){
     syntax += $3->code;
     syntax += "\n";
   }
   syntax += ". ";
   syntax += tempReg;
   syntax += "\n";
   syntax += "/ ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $1->name;
   syntax += ", ";
   syntax += $3->name;
   syntax += "\n";

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);
 }
 ;

term: 
 NUMBER
 {
   string num = $1;
   $$->name = strdup(num.c_str());
   $$->code = ""; //strdup(num.c_str()); 
 }
 | SUB term   
 {
   /*
   string tempReg = "_temp";
   tempReg += SSTR(tempTable.size());
   tempTable.push_back(tempReg.c_str());

   string codeCheck = $2->code;
   string syntax = "";
   if(codeCheck != ""){
     syntax = $2->code;
     syntax += "\n";
   }

   syntax += "* ";
   syntax += tempReg;
   syntax += ", ";
   syntax += $2->name;
   syntax += ", -1";

   CodeNode *node = new CodeNode;
   node->code = (syntax.c_str());
   node->name = (tempReg.c_str());
   $$->code = strdup(node->code);
   $$->name = strdup(node->name);
   */
   string num = "-";
   num += $2->name;
   $$->name = strdup(num.c_str());
   $$->code = strdup($2->code);
 }
 | L_PAREN exp R_PAREN 
 { 
   string expCode = $2->code;
   string expName = $2->name;
   // initailizing CodeNode to check for strange behavior
   CodeNode* node = new CodeNode;
   $$ = node;
   $$->name = strdup(expName.c_str());
   $$->code = strdup(expCode.c_str());
 }
 | IDENTIFIER
 {
  bool undefinedVar = true;
  for(int i = 0; i < identTable.size(); i++){
    if(strcmp(identTable.at(i), $1) == 0){
      undefinedVar = false;
    }
  }
  if(undefinedVar){
    string errorMessage = "Undefined variable ";
    errorMessage += $1;
    yyerror(errorMessage.c_str());
  }
  string src = $1;
  $$->name = strdup(src.c_str());
  $$->code = "";
 }
 | id L_SQUARE_BRACKET exp R_SQUARE_BRACKET {
  // check if array exists/duplicates and check if index in bounds
  //handleAccessArray($1->name, $3);
  
  string tempReg = "_temp";
  tempReg += SSTR(tempTable.size());
  tempTable.push_back(tempReg.c_str());
  

	string expCode = "";
   string codeCheck = $3->code;
   if(codeCheck != ""){
     expCode += $3->code;
   }

	string syntax = expCode;
  syntax += ". ";
  syntax += tempReg;
  syntax += "\n";
  syntax += "=[] ";
  syntax += tempReg;
  syntax += ", ";
  syntax += $1->name;
  syntax += ", ";
  syntax += $3->name;
	syntax += "\n";

  CodeNode *node = new CodeNode;
  $$ = node;
  $$->name = strdup(tempReg.c_str());
  $$->code = strdup(syntax.c_str());
 }
 | id L_PAREN parameters R_PAREN { // calling a function
  string tempReg = "_temp";
  tempReg += SSTR(tempTable.size());
  tempTable.push_back(tempReg.c_str());

  // store result of function into temp the name of this term -> temp
  // call params as param varname 
   
  string syntax = $3->code;
  syntax += ". ";
  syntax += tempReg;
  syntax += "\n";
  syntax += "call ";
  syntax += $1->name;
  syntax += ", ";
  syntax += tempReg;
	syntax += "\n";

  CodeNode *node = new CodeNode;
  $$ = node;
  $$->name = strdup(tempReg.c_str());
  $$->code = strdup(syntax.c_str());
 }
 ;

%%
main(int argc, char **argv)
{
    ++argv, --argc;  /* skip over program name */
    if ( argc > 0 )
        yyin = fopen( argv[0], "r");
    else
        yyin = stdin;

    yyparse();
}




