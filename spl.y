%define parse.trace

%{

/* declare some standard headers to be used to import declarations
   and libraries into the parser. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* make forward declarations to avoid compiler warnings */
int yylex (void);
void yyerror (char *);

/* 
   Some constants.
*/

  /* These constants are used later in the code */
#define SYMTABSIZE     50
#define IDLENGTH       15
#define REALLENGTH     32
#define NOTHING        -1
#define INDENTOFFSET    2

enum ParseTreeNodeType
{
	dunno
	/* Add more types here, as more nodes added to tree */
};

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

#ifndef NULL
#define NULL 0
#endif

/* ------------- parse tree definition --------------------------- */

struct treeNode {
    union
    {
      long integer;
      char real[REALLENGTH];
    } value;
    int  nodeIdentifier;
    struct treeNode *first;
    struct treeNode *second;
    struct treeNode *third;
    struct treeNode *fourth;
  };

typedef  struct treeNode TREE_NODE;
typedef  TREE_NODE        *QUATERNARY_TREE;

/* ------------- forward declarations --------------------------- */

static QUATERNARY_TREE create_node(int,QUATERNARY_TREE,QUATERNARY_TREE,QUATERNARY_TREE,QUATERNARY_TREE);
static void OptimiseTree(QUATERNARY_TREE t);
static void FreeTree(QUATERNARY_TREE t);
static void PrintTree(QUATERNARY_TREE t);

/* ------------- symbol table definition --------------------------- */

struct symTabNode {
    char identifier[IDLENGTH];
    int type;
};

typedef  struct symTabNode SYMTABNODE;
typedef  SYMTABNODE        *SYMTABNODEPTR;

SYMTABNODEPTR  symTab[SYMTABSIZE]; 

long currentSymTabSize = 0;

%}

/****************/
/* Start symbol */
/****************/

%start  statement_list

/**********************/
/* Action value types */
/**********************/
/*
%union {
    long iVal;
    char fVal[REALLENGTH];
    QUATERNARY_TREE  tVal;
}
*/
/* We can declare types of tree nodes */

%token TOKEN_DOT
%token TOKEN_COMMA
%token TOKEN_NEWLINE
%token TOKEN_OPCODE_MOVE
%token TOKEN_OPCODE_ADD
%token TOKEN_LEFT_PARENTHESIS
%token TOKEN_RIGHT_PARENTHESIS
%token TOKEN_SIZE_BYTE
%token TOKEN_SIZE_SHORT
%token TOKEN_SIZE_WORD
%token TOKEN_SIZE_LONG
%token TOKEN_DOLLAR
%token TOKEN_DATA_REGISTER
%token TOKEN_ADDRESS_REGISTER
%token TOKEN_NUMBER

/*
%token<iVal> CHARACTER_CONSTANT IDENTIFIER NUMBER
%token<fVal> REAL_NUMBER

%type<tVal> program block declaration_block declaration type statement_list statement assignment_statement if_statement do_statement while_statement for_statement write_statement read_statement output_list conditional subconditional comparator expression term value constant number_constant
*/
%%

statement_list       : statement
                     | statement statement_list
					 ;

statement            : TOKEN_NEWLINE
                     | full_opcode operand_list TOKEN_NEWLINE
					 ;

full_opcode          : opcode
                     | opcode TOKEN_DOT size
					 ;

opcode               : TOKEN_OPCODE_MOVE
                     | TOKEN_OPCODE_ADD
                     ;

size                 : TOKEN_SIZE_BYTE
                     | TOKEN_SIZE_SHORT
                     | TOKEN_SIZE_WORD
                     | TOKEN_SIZE_LONG
                     ;

operand_list         : operand
                     | operand TOKEN_COMMA operand_list
					 ;

operand              : register
                     | address
                     ;

register             : TOKEN_DATA_REGISTER
                     | TOKEN_ADDRESS_REGISTER
					 ;

address              : number
                     | number TOKEN_DOT size
                     | TOKEN_LEFT_PARENTHESIS number TOKEN_RIGHT_PARENTHESIS
                     | TOKEN_LEFT_PARENTHESIS number TOKEN_RIGHT_PARENTHESIS TOKEN_DOT size
					 ;

number               : TOKEN_NUMBER
                     | TOKEN_DOLLAR TOKEN_NUMBER
					 ;

/*
program              : IDENTIFIER COLON block ENDP IDENTIFIER DOT
                     {
                       QUATERNARY_TREE tree;
                       tree = create_node(PROGRAM, $3, NULL, NULL, NULL);
                       if (tree != NULL)
                       {
                         tree->value.integer = $1;

                         OptimiseTree(tree);
                         PrintTree(tree);
                         FreeTree(tree);
                       }
                     }
                     ;
block                : DECLARATIONS declaration_block CODE statement_list
                     {
                       $$ = create_node(BLOCK, $2, $4, NULL, NULL);
                     }
                     | CODE statement_list
                     {
                       $$ = create_node(BLOCK, NULL, $2, NULL, NULL);
                     }
                     ;
declaration_block    : declaration OF TYPE type SEMICOLON declaration_block
                     {
                       $$ = create_node(DECLARATION_BLOCK, $1, $4, $6, NULL);
                     }
                     | declaration OF TYPE type SEMICOLON
                     {
                       $$ = create_node(DECLARATION_BLOCK, $1, $4, NULL, NULL);
                     }
                     ;
declaration          : IDENTIFIER COMMA declaration
                     {
                       $$ = create_node(DECLARATION, $3, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = $1;
                     }
                     | IDENTIFIER
                     {
                       $$ = create_node(DECLARATION, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = $1;
                     }
                     ;
type                 : CHARACTER
                     {
                       $$ = create_node(TYPE_RULE, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = CHARACTER;
                     }
                     | INTEGER
                     {
                       $$ = create_node(TYPE_RULE, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = INTEGER;
                     }
                     | REAL
                     {
                       $$ = create_node(TYPE_RULE, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = REAL;
                     }
                     ;
statement_list       : statement SEMICOLON statement_list
                     {
                       $$ = create_node(STATEMENT_LIST, $1, $3, NULL, NULL);
                     }
                     | statement
                     {
                       $$ = create_node(STATEMENT_LIST, $1, NULL, NULL, NULL);
                     }
                     ;
statement            : assignment_statement
                     {
                       $$ = create_node(STATEMENT, $1, NULL, NULL, NULL);
                     }
                     | if_statement
                     {
                       $$ = create_node(STATEMENT, $1, NULL, NULL, NULL);
                     }
                     | do_statement
                     {
                       $$ = create_node(STATEMENT, $1, NULL, NULL, NULL);
                     }
                     | while_statement
                     {
                       $$ = create_node(STATEMENT, $1, NULL, NULL, NULL);
                     }
                     | for_statement
                     {
                       $$ = create_node(STATEMENT, $1, NULL, NULL, NULL);
                     }
                     | write_statement
                     {
                       $$ = create_node(STATEMENT, $1, NULL, NULL, NULL);
                     }
                     | read_statement
                     {
                       $$ = create_node(STATEMENT, $1, NULL, NULL, NULL);
                     }
                     ;
assignment_statement : expression ARROW IDENTIFIER
                     {
                       $$ = create_node(ASSIGNMENT_STATEMENT, $1, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = $3;
                     }
                     ;
if_statement         : IF conditional THEN statement_list ELSE statement_list ENDIF
                     {
                       $$ = create_node(IF_STATEMENT, $2, $4, $6, NULL);
                     }
                     | IF conditional THEN statement_list ENDIF
                     {
                       $$ = create_node(IF_STATEMENT, $2, $4, NULL, NULL);
                     }
                     ;
do_statement         : DO statement_list WHILE conditional ENDDO
                     {
                       $$ = create_node(DO_STATEMENT, $2, $4, NULL, NULL);
                     }
                     ;
while_statement      : WHILE conditional DO statement_list ENDWHILE
                     {
                       $$ = create_node(WHILE_STATEMENT, $2, $4, NULL, NULL);
                     }
                     ;
for_statement        : FOR IDENTIFIER IS expression BY expression TO expression DO statement_list ENDFOR
                     {
                       $$ = create_node(FOR_STATEMENT, $4, $6, $8, $10);
                       if ($$ != NULL)
                         $$->value.integer = $2;
                     }
                     ;
write_statement      : NEWLINE
                     {
                       $$ = create_node(WRITE_STATEMENT, NULL, NULL, NULL, NULL);
                     }
                     | WRITE LEFT_PARENTHESIS output_list RIGHT_PARENTHESIS
                     {
                       $$ = create_node(WRITE_STATEMENT, $3, NULL, NULL, NULL);
                     }
                     ;
read_statement       : READ LEFT_PARENTHESIS IDENTIFIER RIGHT_PARENTHESIS
                     {
                       $$ = create_node(READ_STATEMENT, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = $3;
                     }
                     ;
output_list          : value COMMA output_list
                     {
                       $$ = create_node(OUTPUT_LIST, $1, $3, NULL, NULL);
                     }
                     | value
                     {
                       $$ = create_node(OUTPUT_LIST, $1, NULL, NULL, NULL);
                     }
                     ;
conditional          : subconditional AND conditional
                     {
                       $$ = create_node(CONDITIONAL, $1, $3, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = AND;
                     }
                     | subconditional OR conditional
                     {
                       $$ = create_node(CONDITIONAL, $1, $3, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = OR;
                     }
                     | subconditional
                     {
                       $$ = create_node(CONDITIONAL, $1, NULL, NULL, NULL);
                     }
                     ;
subconditional       : NOT subconditional
                     {
                       $$ = create_node(SUBCONDITIONAL, $2, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = NOT;
                     }
                     | expression comparator expression
                     {
                       $$ = create_node(SUBCONDITIONAL, $1, $2, $3, NULL);
                       if ($$ != NULL)
                         $$->value.integer = NOTHING;
                     }
                     ;
comparator           : EQUAL
                     {
                       $$ = create_node(COMPARATOR, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = EQUAL;
                     }
                     | INEQUAL
                     {
                       $$ = create_node(COMPARATOR, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = INEQUAL;
                     }
                     | LESS
                     {
                       $$ = create_node(COMPARATOR, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = LESS;
                     }
                     | MORE
                     {
                       $$ = create_node(COMPARATOR, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = MORE;
                     }
                     | LESS_OR_EQUAL
                     {
                       $$ = create_node(COMPARATOR, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = LESS_OR_EQUAL;
                     }
                     | MORE_OR_EQUAL
                     {
                       $$ = create_node(COMPARATOR, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = MORE_OR_EQUAL;
                     }
                     ;
expression           : term PLUS expression
                     {
                       $$ = create_node(EXPRESSION, $1, $3, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = PLUS;
                     }
                     | term MINUS expression
                     {
                       $$ = create_node(EXPRESSION, $1, $3, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = MINUS;
                     }
                     | term
                     {
                       $$ = create_node(EXPRESSION, $1, NULL, NULL, NULL);
                     }
                     ;
term                 : value MULTIPLY term
                     {
                       $$ = create_node(TERM, $1, $3, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = MULTIPLY;
                     }
                     | value DIVIDE term
                     {
                       $$ = create_node(TERM, $1, $3, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = DIVIDE;
                     }
                     | value
                     {
                       $$ = create_node(TERM, $1, NULL, NULL, NULL);
                     }
                     ;
value                : IDENTIFIER
                     {
                       $$ = create_node(VALUE_IDENTIFIER, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = $1;
                     }
                     | constant
                     {
                       $$ = create_node(VALUE_CONSTANT, $1, NULL, NULL, NULL);
                     }
                     | LEFT_PARENTHESIS expression RIGHT_PARENTHESIS
                     {
                       $$ = create_node(VALUE_EXPRESSION, $2, NULL, NULL, NULL);
                     }
                     ;
constant             : number_constant
                     {
                       $$ = create_node(CONSTANT_NUMBER, $1, NULL, NULL, NULL);
                     }
                     | CHARACTER_CONSTANT
                     {
                       $$ = create_node(CONSTANT_CHARACTER, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = $1;
                     }
                     ;
number_constant      : MINUS REAL_NUMBER
                     {
                       $$ = create_node(REAL_NUMBER_CONSTANT, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                       {
                         $$->value.real[0] = '-';
                         memcpy($$->value.real + 1, $2, REALLENGTH - 2);
                         $$->value.real[REALLENGTH - 1] = '\0';
                       }
                     }
                     | REAL_NUMBER
                     {
                       $$ = create_node(REAL_NUMBER_CONSTANT, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         memcpy($$->value.real, $1, REALLENGTH);
                     }
                     | MINUS NUMBER
                     {
                       $$ = create_node(NUMBER_CONSTANT, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = -$2;
                     }
                     | NUMBER
                     {
                       $$ = create_node(NUMBER_CONSTANT, NULL, NULL, NULL, NULL);
                       if ($$ != NULL)
                         $$->value.integer = $1;
                     }
                     ;
*/
%%

/* Put other auxiliary functions here */

/*#include "lexer.c"*/
