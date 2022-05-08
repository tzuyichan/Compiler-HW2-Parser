#include "table_list.h"

#define FAIL_IF(EXP, MSG)                        \
    {                                            \
        if (EXP)                                 \
        {                                        \
            fprintf(stderr, "Error! " MSG "\n"); \
            exit(EXIT_FAILURE);                  \
        }                                        \
    }

struct list_t
{
    Node *first;
};

List *init_list()
{
    List *L;
    FAIL_IF(!(L = malloc(sizeof(List))), "List malloc failure!");
    L->first = NULL;

    return L;
}

Node *init_node()
{
    Node *N;
    FAIL_IF(!(N = malloc(sizeof(Node))), "Node malloc failure!");
    N->index = -1;
    strcpy(N->name, "?");
    strcpy(N->type, "?");
    N->addr = -2;
    N->lineno = -1;
    strcpy(N->func_sig, "?");
    N->next = NULL;

    return N;
}

int enqueue(List *L, Node *N)
{
    Node *p;

    for (p = L->first; p != NULL; p = p->next)
    {
        if (p->name == N->name)
            return -1;
        if (!p->next)
            break;
    } // p = last node in the linked list

    if (!p)
        L->first = N;
    else
        p->next = N;

    return 0;
}