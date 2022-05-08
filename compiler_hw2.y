/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_hw_common.h" //Extern variables that communicate with lex
    #include "symbol_table.h"
    #include "table_list.h"
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
    static void create_sym_table();
    static void insert_symbol(char *name, char *type);
    static void insert_func();
    static void lookup_symbol(char *name);
    static void dump_sym_table();

    /* Global variables */
    bool HAS_ERROR = false;
    int SCOPE_LVL = 0;
    int NEXT_FREE_ADDR = 0;
    char CURRENT_FUNC[ID_MAX_LEN];
    int CURRENT_FUNC_LINENO;
    Table_head *T;
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
        // insert_func(CURRENT_FUNC);
        insert_symbol(CURRENT_FUNC, "func");
    }
    FuncBlock
;

FuncOpen
    : FUNC IDENT {
        strncpy(CURRENT_FUNC, $2, ID_MAX_LEN);
        CURRENT_FUNC_LINENO = yylineno;
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
        insert_symbol($1, $2);
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

StatementList
    : StatementList Statement
    | /* empty */
;

Statement
    : DeclarationStmt NEWLINE
    | SimpleStmt NEWLINE
    /* | Block
    | IfStmt
    | ForStmt
    | SwitchStmt
    | CaseStmt */
    | PrintStmt NEWLINE
    /* | ReturnStmt NEWLINE */
    | NEWLINE
;

DeclarationStmt
    : VAR IDENT Type DeclAssignment     { insert_symbol($2, $3); }
;

DeclAssignment
    : ASSIGN Expression
    | /* empty */
;

SimpleStmt
    : AssignmentStmt
    | Expression
    | IncDecStmt
;

/* IfStmt
    :
;

ForStmt
    :
;

SwitchStmt
    :
;

CaseStmt
    :
; */

PrintStmt
    : PRINT ParenthesisExpr
    | PRINTLN ParenthesisExpr       { printf("PRINTLN %s\n", "int32"); }
;

/* ReturnStmt
    :
; */

AssignmentStmt
    : IDENT ASSIGN Expression
;

IncDecStmt
    : Operand INC       { printf("INC\n"); }
    | Operand DEC       { printf("DEC\n"); }
;

ParenthesisExpr
    : '(' Expression ')'
;

Expression
    : LogOrExpr
;

LogOrExpr
    : LogAndExpr
    | LogOrExpr LOR LogAndExpr           { printf("LOR\n"); }
;

LogAndExpr
    : CmpExpr
    | LogAndExpr LAND CmpExpr          { printf("LAND\n"); }
;

CmpExpr
    : AddExpr
    | CmpExpr EQL AddExpr           { printf("EQL\n"); }
    | CmpExpr NEQ AddExpr           { printf("NEQ\n"); }
    | CmpExpr LSS AddExpr           { printf("LSS\n"); }
    | CmpExpr LEQ AddExpr           { printf("LEQ\n"); }
    | CmpExpr GTR AddExpr           { printf("GTR\n"); }
    | CmpExpr GEQ AddExpr           { printf("GEQ\n"); }
;

AddExpr
    : MulExpr
    | AddExpr ADD MulExpr           { printf("ADD\n"); }
    | AddExpr SUB MulExpr           { printf("SUB\n"); }
;

MulExpr
    : UnaryExpr
    | MulExpr MUL UnaryExpr           { printf("MUL\n"); }
    | MulExpr QUO UnaryExpr           { printf("QUO\n"); }
    | MulExpr REM UnaryExpr           { printf("REM\n"); }
;

UnaryExpr
    : PrimaryExpr
    | ADD PrimaryExpr       { printf("POS\n"); }
    | SUB PrimaryExpr       { printf("NEG\n"); }
    | NOT PrimaryExpr       { printf("NOT\n"); }
;

PrimaryExpr
    : Operand
    | STRING_LIT
    | ParenthesisExpr
;

Operand
    : Constant
    | IDENT             { lookup_symbol($1); }
;

Constant
    : INT_LIT           { printf("INT_LIT %d\n", $1); }
    | FLOAT_LIT         { printf("FLOAT_LIT %f\n", $1); } 
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
    T = init_table();
    yyparse();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_sym_table() {
    add_table(T);
    printf("> Create symbol table (scope level %d)\n", T->current_scope);
}

static void insert_symbol(char *name, char *type) {
    int lineno;
    char func_sig[ID_MAX_LEN];
    if (strcmp(type, "func") == 0)
    {
        // generate function signature
        lineno = CURRENT_FUNC_LINENO;
        strncpy(func_sig, "-", ID_MAX_LEN);
    }
    else
    {
        lineno = yylineno;
        strncpy(func_sig, "-", ID_MAX_LEN);
    }

    Result *entry;
    entry = add_symbol(T, name, type, lineno, func_sig);

    printf("> Insert `%s` (addr: %d) to scope level %d\n", 
           name, entry->addr, entry->scope);
}

static void insert_func(char *name) {
    printf("> Insert `%s` (addr: %d) to scope level %d\n", name, -1, SCOPE_LVL - 1);
}

static void lookup_symbol(char *name) {
    /* printf("lookup func called!\n"); */
    Result *R = find_symbol(T, name);
    if (R)
        printf("IDENT (name=%s, address=%d)\n", name, R->addr); 
    free(R);
}

static void dump_sym_table() {
    printf("\n> Dump symbol table (scope level: %d)\n", 0);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s\n",
           "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");
    printf("%-10d%-10s%-10s%-10d%-10d%-10s\n",
            0, "name", "type", 0, 0, "func_sig");
}