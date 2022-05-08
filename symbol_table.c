#include "symbol_table.h"

#define FAIL_IF(EXP, MSG)                        \
    {                                            \
        if (EXP)                                 \
        {                                        \
            fprintf(stderr, "Error! " MSG "\n"); \
            exit(EXIT_FAILURE);                  \
        }                                        \
    }

struct table_t
{
    int scope;
    int index_cnt;
    List *list;
    Table *next;
};

Table_head *init_table()
{
    Table_head *T;
    FAIL_IF(!(T = malloc(sizeof(Table_head))), "Table head malloc failure!");
    T->current_scope = -1;
    T->next_free_addr = 0;
    T->first = NULL;

    return T;
}

void add_table(Table_head *T)
{
    Table *ST;
    FAIL_IF(!(ST = malloc(sizeof(Table))), "Table malloc failure!");
    ST->scope = ++(T->current_scope);
    ST->index_cnt = 0;
    ST->list = init_list();
    ST->next = T->first;
    T->first = ST;
}

void add_symbol(Table_head *T, char *name, char *type, int lineno, char *func_sig)
{
    Node *N = init_node();
    // copy table contents into new node
    N->index = (T->first->index_cnt)++;
    strncpy(N->name, name, ID_MAX_LEN);
    strncpy(N->type, type, 8);
    N->addr = (T->next_free_addr)++;
    N->lineno = lineno;
    strncpy(N->func_sig, func_sig, ID_MAX_LEN);
    N->next = NULL;

    enqueue(T->first->list, N);
    printf("index: %d, name: %s, type: %s, addr: %d, line#: %d, func: %s\n",
           N->index, N->name, N->type, N->addr, N->lineno, N->func_sig);
}