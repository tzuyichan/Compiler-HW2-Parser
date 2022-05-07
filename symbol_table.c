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
    Table *next;
};

Table_head *init_table()
{
    Table_head *T;
    FAIL_IF(!(T = malloc(sizeof(Table_head))), "Table head malloc failure!");
    T->current_scope = -1;
    T->next_free_addr = 0;
    T->table = NULL;

    return T;
}

{
    return a + b;
}