#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "table_list.h"

typedef struct table_t Table;
typedef struct
{
    int current_scope;
    int next_free_addr;
    Table *table;
} Table_head;

Table_head *init_table();

#endif