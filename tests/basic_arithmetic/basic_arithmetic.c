#include "string.h"
#define DEBUG_IF_ADDR 0x00002010

int e, h, k, l;

void basic_arithmetic(int x, int y, int z, int f, int g)
{
    e = x + y;
    h = y - z; 
    k = z + f;
    l = f - g;
}

int main() 
{
    basic_arithmetic(4, 33, 15, 27, 12);

    int *addr_ptr = (int*)DEBUG_IF_ADDR;
    if(e == 37 && h == 18 && k == 42 && l == 15)
    {
        //success
        *addr_ptr = 1;
    }
    else
    {
        //failure
        *addr_ptr = 0;
    }
    return 0;
}
