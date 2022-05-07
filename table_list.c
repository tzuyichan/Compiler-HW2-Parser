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