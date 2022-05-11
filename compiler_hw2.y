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
    static void lookup_symbol(char *name);
    static void dump_sym_table();
    static char *check_type(char *nterm1, char *nterm2, int operator);

    /* Global variables */
    bool HAS_ERROR = false;
    char TYPE[8];
    char CURRENT_FUNC[ID_MAX_LEN];
    int CURRENT_FUNC_LINENO;
    char FUNC_RET_TYPE;
    bool IN_FUNC_SCOPE = false;
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
%type <s_val> ParenthesisExpr Expression 
%type <s_val> LogOrExpr LogAndExpr CmpExpr AddExpr MulExpr
%type <s_val> CastExpr UnaryExpr PrimaryExpr Boolean Operand Constant

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
        FUNC_RET_TYPE = $5[0] - 32;  // ASCII case conversion
        insert_symbol(CURRENT_FUNC, "func");
    }
    FuncBlock
;

FuncOpen
    : FUNC IDENT {
        printf("func: %s\n", $2);
        strncpy(CURRENT_FUNC, $2, ID_MAX_LEN);
        CURRENT_FUNC_LINENO = yylineno;
        create_sym_table();
        IN_FUNC_SCOPE = true;
    }
;

ParameterList
    : ParameterList ',' ParameterIdentType
    | ParameterIdentType
    | /* empty */
;

ReturnType
    : Type
    | /* empty */       { $$ = "void"; }
;

FuncBlock
    : Block
;
    
ReturnStmt
    : RETURN                { printf("return\n"); }
    | RETURN Expression     { printf("xreturn\n"); }
;

ParameterIdentType
    : IDENT Type {
        printf("param %s, type: %c\n", $1, $2[0] - 32);
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
    : '{' { create_sym_table(); } StatementList '}' { dump_sym_table(); }
;

StatementList
    : StatementList Statement
    | /* empty */
;

Statement
    : DeclarationStmt NEWLINE
    | SimpleStmt NEWLINE
    | Block
    | IfStmt
    | ForStmt
    /* | SwitchStmt
    | CaseStmt */
    | PrintStmt NEWLINE
    | ReturnStmt NEWLINE
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

IfStmt
    : IF Expression Block ElseStmt
;

ElseStmt
    : ELSE IfStmt
    | ELSE Block
    | /* empty */
;

ForStmt
    : FOR Expression Block
    | FOR ForClause Block
;

ForClause
    : SimpleStmt ';' Expression ';' SimpleStmt
;

/* SwitchStmt
    :
;

CaseStmt
    :
; */

PrintStmt
    : PRINT ParenthesisExpr
    | PRINTLN ParenthesisExpr       { printf("PRINTLN %s\n", "int32"); }
;

AssignmentStmt
    : IDENT { lookup_symbol($1); } ASSIGN Expression { printf("ASSIGN\n"); }
    | IDENT { lookup_symbol($1); } ADD_ASSIGN Expression { printf("ADD\n"); }
    | IDENT { lookup_symbol($1); } SUB_ASSIGN Expression { printf("SUB\n"); }
    | IDENT { lookup_symbol($1); } MUL_ASSIGN Expression { printf("MUL\n"); }
    | IDENT { lookup_symbol($1); } QUO_ASSIGN Expression { printf("QUO\n"); }
    | IDENT { lookup_symbol($1); } REM_ASSIGN Expression { printf("REM\n"); }
;

IncDecStmt
    : Operand INC       { printf("INC\n"); }
    | Operand DEC       { printf("DEC\n"); }
;

ParenthesisExpr
    : '(' Expression ')'        { $$ = $2; }
;

Expression
    : LogOrExpr
;

LogOrExpr
    : LogAndExpr
    | LogOrExpr LOR LogAndExpr           { $$ = "bool"; printf("LOR\n"); }
;

LogAndExpr
    : CmpExpr
    | LogAndExpr LAND CmpExpr          { $$ = "bool"; printf("LAND\n"); }
;

CmpExpr
    : AddExpr
    | CmpExpr EQL AddExpr          { $$ = "bool"; printf("EQL\n"); }
    | CmpExpr NEQ AddExpr          { $$ = "bool"; printf("NEQ\n"); }
    | CmpExpr LSS AddExpr          { $$ = "bool"; printf("LSS\n"); }
    | CmpExpr LEQ AddExpr          { $$ = "bool"; printf("LEQ\n"); }
    | CmpExpr GTR AddExpr          { $$ = "bool"; printf("GTR\n"); }
    | CmpExpr GEQ AddExpr          { $$ = "bool"; printf("GEQ\n"); }
;

AddExpr
    : MulExpr
    | AddExpr ADD MulExpr           { $$ = check_type($1, $3, ADD); 
    // printf("in Add: AddExpr=%s, MulExpr=%s\n",$1,$3);
    printf("ADD\n"); }
    | AddExpr SUB MulExpr           { $$ = check_type($1, $3, SUB); printf("SUB\n"); }
;

MulExpr
    : CastExpr
    | MulExpr MUL CastExpr           { $$ = check_type($1, $3, MUL); printf("MUL\n"); }
    | MulExpr QUO CastExpr           { $$ = check_type($1, $3, QUO); printf("QUO\n"); }
    | MulExpr REM CastExpr           { $$ = check_type($1, $3, REM); printf("REM\n"); }
;

CastExpr
    : UnaryExpr
    | INT '(' AddExpr ')'          { $$ = "int32"; printf("f2i\n"); }
    | FLOAT '(' AddExpr ')'        { $$ = "float32"; printf("i2f\n"); }
;

UnaryExpr
    : PrimaryExpr
    | ADD PrimaryExpr       { $$ = check_type($2, $2, ADD); printf("POS\n"); }
    | SUB PrimaryExpr       { $$ = check_type($2, $2, SUB); printf("NEG\n"); }
    | NOT UnaryExpr         { $$ = "bool"; printf("NOT\n"); }
;

PrimaryExpr
    : Operand
    | '"' STRING_LIT '"'    { $$ = "string"; printf("STRING_LIT %s\n", $2); }
    | Boolean
    | ParenthesisExpr
;

Operand
    : Constant
    | IDENT             { lookup_symbol($1); $$ = TYPE; }
;

Boolean
    : TRUE_             { $$ = "bool"; printf("TRUE 1\n"); }
    | FALSE_            { $$ = "bool"; printf("FALSE 0\n"); }
;

Constant
    : INT_LIT           { $$ = "int32"; printf("INT_LIT %d\n", $1); }
    | FLOAT_LIT         { $$ = "float32"; printf("FLOAT_LIT %f\n", $1); } 
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

    // initialize global strings
    memset(TYPE, 0, 8);
    memset(CURRENT_FUNC, 0, ID_MAX_LEN);

    yylineno = 0;
    T = init_table();
    yyparse();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_sym_table() {
    if (!IN_FUNC_SCOPE)
    {
        add_table(T);
        printf("> Create symbol table (scope level %d)\n", T->current_scope);
    }
    IN_FUNC_SCOPE = false;
}

static void insert_symbol(char *name, char *type) {
    int lineno;
    char type_str[ID_MAX_LEN];
    char func_sig[ID_MAX_LEN];
    memset(type_str, '\0', ID_MAX_LEN);
    memset(func_sig, '\0', ID_MAX_LEN);

    if (strcmp(type, "func") == 0)
    {
        // generate function signature
        lineno = CURRENT_FUNC_LINENO;
        get_func_param_types(T, type_str);
        snprintf(func_sig, ID_MAX_LEN, "(%s)%c", type_str, FUNC_RET_TYPE);
        printf("func_signature: %s\n", func_sig);
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

    free(entry);
}

static void lookup_symbol(char *name) {
    /* printf("lookup func called!\n"); */
    Result *R = find_symbol(T, name);
    if (R)
    {
        strncpy(TYPE, R->type, 8);
        printf("IDENT (name=%s, address=%d)\n", name, R->addr); 
    }
    free(R);
}

static void dump_sym_table() {
    printf("\n> Dump symbol table (scope level: %d)\n", T->current_scope);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s\n",
           "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");

    Node *entry;
    while ((entry = dump_next_entry(T)))
    {
        printf("%-10d%-10s%-10s%-10d%-10d%-10s\n",
               entry->index, entry->name, entry->type,
               entry->addr, entry->lineno, entry->func_sig);
        free(entry);
    }
    printf("\n");
    delete_table(T);
}

static char *check_type(char *nterm1, char *nterm2, int operator)
{
    if (strcmp(nterm1, nterm2) == 0)
    {
        return nterm1;
    }
    else
    {
        /* printf("nterm1: %s, nterm2: %s\n", nterm1, nterm2); */
        return "ERROR";
    }
}