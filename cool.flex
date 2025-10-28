%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <string.h>

extern FILE *fin;
#define YY_NO_UNPUT

extern int curr_lineno;
#define yylval cool_yylval
#define yylex cool_yylex
#define MAX_STR_CONST 1025

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
    if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
        YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST];
char *string_buf_ptr;
static int comment_level = 0;

bool string_overflow() {
    return string_buf_ptr - string_buf + 1 >= MAX_STR_CONST;
}

extern "C" int yywrap() { return 1; }
%}

%option yylineno
%x COMMENT
%x STRING
%%

"class"     { return CLASS; }
"else"      { return ELSE; }
"fi"        { return FI; }
"if"        { return IF; }
"in"        { return IN; }
"inherits"  { return INHERITS; }
"isvoid"    { return ISVOID; }
"let"       { return LET; }
"loop"      { return LOOP; }
"pool"      { return POOL; }
"then"      { return THEN; }
"while"     { return WHILE; }
"case"      { return CASE; }
"esac"      { return ESAC; }
"new"       { return NEW; }
"of"        { return OF; }
"not"       { return NOT; }
"true"      { 
    cool_yylval.boolean = 1; 
    return BOOL_CONST; 
}
"false"     { 
    cool_yylval.boolean = 0; 
    return BOOL_CONST; 
}
[A-Z][a-zA-Z0-9_]* { 
    cool_yylval.symbol = stringtable.add_string(yytext); 
    return TYPEID; 
}
[a-z][a-zA-Z0-9_]* { 
    cool_yylval.symbol = stringtable.add_string(yytext); 
    return OBJECTID; 
}
[0-9]+      { 
    cool_yylval.symbol = stringtable.add_string(yytext); 
    return INT_CONST; 
}
"=>"        { return DARROW; }
"<-"        { return ASSIGN; }
"<="        { return LE; }
"+"         { return '+'; }
"-"         { return '-'; }
"*"         { return '*'; }
"/"         { return '/'; }
"~"         { return '~'; }
"<"         { return '<'; }
"="         { return '='; }
"."         { return '.'; }
"@"         { return '@'; }
","         { return ','; }
";"         { return ';'; }
"("         { return '('; }
")"         { return ')'; }
"{"         { return '{'; }
"}"         { return '}'; }
":"         { return ':'; }
"|"         { return '|'; }
\"          { 
    BEGIN(STRING); 
    string_buf_ptr = string_buf; 
}
<STRING>\"  { 
    *string_buf_ptr = '\0'; 
    cool_yylval.symbol = stringtable.add_string(string_buf); 
    BEGIN(INITIAL); 
    return STR_CONST; 
}
<STRING>\n  { 
    curr_lineno++; 
    cool_yylval.error_msg = "Unterminated string constant";
    BEGIN(INITIAL); 
    return ERROR; 
}
<STRING>\\n { 
    if (string_overflow()) {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(INITIAL);
        return ERROR;
    }
    *string_buf_ptr++ = '\n'; 
}
<STRING>\\t { 
    if (string_overflow()) {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(INITIAL);
        return ERROR;
    }
    *string_buf_ptr++ = '\t'; 
}
<STRING>\\\\ { 
    if (string_overflow()) {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(INITIAL);
        return ERROR;
    }
    *string_buf_ptr++ = '\\'; 
}
<STRING>\\\"  { 
    if (string_overflow()) {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(INITIAL);
        return ERROR;
    }
    *string_buf_ptr++ = '"'; 
}
<STRING>.   { 
    if (string_overflow()) {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(INITIAL);
        return ERROR;
    }
    *string_buf_ptr++ = yytext[0]; 
}
<STRING><<EOF>>     {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(INITIAL);
    return ERROR;
}
"(*"        { 
    BEGIN(COMMENT); 
    comment_level = 1; 
}
<COMMENT>"(*" { comment_level++; }
<COMMENT>"*)" { 
    comment_level--; 
    if (comment_level == 0) BEGIN(INITIAL); 
}
<COMMENT>\n { curr_lineno++; }
<COMMENT>.  { }
<COMMENT><<EOF>>   {
    cool_yylval.error_msg = "EOF in comment";
    BEGIN(INITIAL);
    return (ERROR);
}
"*)"                {
    cool_yylval.error_msg = "Unmatched *)";
    return (ERROR);
}
--[^\n]*            ;
[ \t\r\n]+  { 
    if (yytext[0] == '\n') 
        curr_lineno++; 
}
.           { 
    cool_yylval.error_msg = strdup(yytext);
    return ERROR;
}

%%

void init_lexer() { 
    string_buf_ptr = string_buf; 
    comment_level = 0; 
    BEGIN(INITIAL); 
}
