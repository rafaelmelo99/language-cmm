/* calculator with AST */

%{
#  include <stdio.h>
#  include <stdlib.h>
#  include "cmm_func.h"
%}

%union {
  struct ast *a;
  double d;
  struct symbol *s;		/* qual simbolo */
  struct symlist *sl;
  int fn;			/* qual funcao */
}


%token <d> NUMBER
%token <s> NAME
%token <fn> FUNC

%token IF THEN ELSE WHILE DO TYPE 


%nonassoc <fn> CMP
%right '='
%left '+' '-'
%left '*' '/'


%type <a> exp stmt list explist
%type <sl> symlist

%start calclist

%%

stmt: IF '(' exp ')' '{' list '}'          { $$ = newflow('I', $3, $6, NULL); }
   | IF '(' exp ')' '{' list '}' ELSE '{' list '}'  { $$ = newflow('I', $3, $6, $10); }
   | WHILE '(' exp ')' '{' list '}'           { $$ = newflow('W', $3, $6, NULL); }
   | DO '{' list '}' WHILE '(' exp ')'        { $$ = newflow('W', $7, $3, NULL); }
   | exp
;

list: /* nothing */ { $$ = NULL; }
   | stmt ';' list { if ($3 == NULL)
	                $$ = $1;
                      else
			$$ = newast('L', $1, $3);
                    }
   ;

exp: exp CMP exp          { $$ = newcmp($2, $1, $3); }
   | exp '+' exp          { $$ = newast('+', $1,$3); }
   | exp '-' exp          { $$ = newast('-', $1,$3);}
   | exp '*' exp          { $$ = newast('*', $1,$3); }
   | exp '/' exp          { $$ = newast('/', $1,$3); }
   | '(' exp ')'          { $$ = $2; }
   | NUMBER               { $$ = newnum($1); }
   | FUNC '(' explist ')' { $$ = newfunc($1, $3); }
   | NAME                 {struct symbol *sp = lookup((char *)$1); $$ = newnum(sp->value);}
   | TYPE NAME                 { lookup((char *)$2); $$ = newref($2); }
   | TYPE NAME '=' exp         { struct symbol *sp = lookup((char *)$2); sp->value = eval($4); $$ = newasgn($2, $4); }
   | NAME '=' exp { struct symbol *sp = lookup((char *)$1); sp->value = eval($3); $$ = newasgn($1, $3); } 
   | NAME '(' explist ')' { $$ = newcall($1, $3); }
;

explist: exp
 | exp ',' explist  { $$ = newast('L', $1, $3); }
;
symlist: NAME       { $$ = newsymlist($1, NULL); }
 | NAME ',' symlist { $$ = newsymlist($1, $3); }
 | /* Nothing */
;

calclist: /* Nothing */ 
   |calclist TYPE NAME '(' symlist ')' '{' list '}' {
                       dodef($3, $5, $8);
                       eval($8);}
 ;
%%
