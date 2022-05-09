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

Result *add_symbol(Table_head *T, char *name, char *type, int lineno, char *func_sig)
{
    Node *entry = init_node();

    bool is_func = strcmp(type, "func") == 0 ? true : false;
    // copy table contents into new node
    entry->index = is_func ? (T->first->next->index_cnt)++ : (T->first->index_cnt)++;
    strncpy(entry->name, name, ID_MAX_LEN);
    strncpy(entry->type, type, 8);
    entry->addr = is_func ? -1 : (T->next_free_addr)++;
    entry->lineno = lineno;
    strncpy(entry->func_sig, func_sig, ID_MAX_LEN);
    entry->next = NULL;

    if (is_func)
        enqueue(T->first->next->list, entry);
    else
        enqueue(T->first->list, entry);

    Result *result;
    FAIL_IF(!(result = malloc(sizeof(Result))), "Insert result malloc failure!");
    result->addr = entry->addr;
    result->scope = is_func ? T->first->next->scope : T->current_scope;
    // printf("index: %d, name: %s, type: %s, addr: %d, line#: %d, func: %s\n",
    //        entry->index, entry->name, entry->type, entry->addr, entry->lineno, entry->func_sig);

    return result;
}

Result *find_symbol(Table_head *T, char *name)
{
    Result *R;

    for (Table *p = T->first; p != NULL; p = p->next)
    {
        if ((R = get_entry(p->list, name)))
            return R;
        if (!p->next)
            break;
    }

    return NULL;
}

Node *dump_next_entry(Table_head *T)
{
    return dequeue(T->first->list);
}

void delete_table(Table_head *T)
{
    Table *p;
    if ((p = T->first))
    {
        T->first = p->next;
        p->next = NULL;
    }

    (T->current_scope)--;

    delete_list(p->list);
    free(p);
}