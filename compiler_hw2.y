/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_hw_common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void insert_symbol();
    static void lookup_symbol();
    static void dump_symbol();

    /* Global variables */
    bool HAS_ERROR = false;
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    /* ... */
}

/* Token without return */
%token INT FLOAT BOOL STRING
%token NOT TRUE_ FALSE_
%token MUL QUO REM
%token ADD SUB
%token INC DEC 
%token EQL NEQ GTR GEQ LSS LEQ 
%token LAND LOR
%token VAR 
%token ASSIGN ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token IF ELSE FOR SWITCH CASE DEFAULT
%token PRINT PRINTLN NEWLINE
%token PACKAGE FUNC RETURN

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT IDENT 

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type ReturnType 

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : { create_sym_table(); } GlobalStatementList { dump_sym_table(); }
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | GlobalStatement
;

GlobalStatement
    : PackageStmt NEWLINE
    | FunctionDeclStmt
    | NEWLINE
;


PackageStmt
    : PACKAGE IDENT     { printf("package: %s\n", $2); }
;

FunctionDeclStmt
    : FuncOpen '(' ParameterList ')' ReturnType {
        printf("func_signature: ()%c\n", $5[0]);
        insert_func(CURRENT_FUNC);
    }
    FuncBlock
;

FuncOpen
    : FUNC IDENT {
        strncpy(CURRENT_FUNC, $2, ID_MAX_LEN);
        printf("func: %s\n", CURRENT_FUNC);
        SCOPE_LVL++;
        create_sym_table();
    }
;

ParameterList
    : ParameterList ',' ParameterIdentType
    | ParameterIdentType
    | /* empty */
;

ReturnType
    : Type
    | /* empty */       { $$ = "V"; }
;

FuncBlock
    : Block
;

ParameterIdentType
    : IDENT Type {
        printf("param %s, type: %c\n", $1, $2[0]);
        insert_symbol($1);
    }
;

Type
    : INT           { $$ = "int32"; }
    | FLOAT         { $$ = "float32"; }
    | STRING        { $$ = "string"; }
    | BOOL          { $$ = "bool"; }
;

Block
    : '{' StatementList '}'
;

    :
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yylineno = 0;
    yyparse();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_symbol() {
    printf("> Create symbol table (scope level %d)\n", 0);
}

static void insert_symbol() {
    printf("> Insert `%s` (addr: %d) to scope level %d\n", "XXX", 0, 0);
}

static void lookup_symbol() {
}

static void dump_symbol() {
    printf("\n> Dump symbol table (scope level: %d)\n", 0);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s\n",
           "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");
    printf("%-10d%-10s%-10s%-10d%-10d%-10s\n",
            0, "name", "type", 0, 0, "func_sig");
}