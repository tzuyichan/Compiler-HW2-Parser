#ifndef TABLE_LIST_H
#define TABLE_LIST_H

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "compiler_hw_common.h"

typedef struct list_t List;
typedef struct node_t
{
    int index;
    char name[ID_MAX_LEN];
    char type[8];
    int addr;
    int lineno;
    char func_sig[ID_MAX_LEN];
    struct node_t *next;
} Node;

List *init_list();

#endif