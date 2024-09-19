#include <stdlib.h>
int IsPrime(int test)
{
    for (int i = 2; i * i <= test; i++)
    {
        if (test % i == 0)
        {
            return -1;
        }
    }
    return 0;
}

int *primes(int n)
{
    int *p = malloc(n * sizeof(int));
    int state = 0;
    int current = 2;
    while (state < n)
    {
        if (IsPrime(current) == 0)
        {
            p[state++] = current;
        }
        current++;
    }
    return p;
}