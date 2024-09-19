#include <stdlib.h>
#include <stdio.h>
int sstrlen(char *p)
{
    int n = 0;
    while (p[n++] != '\0')
    {
    }
    return n - 1;
}

void replace(char *source, char *destination, size_t offset)
{
    while (*source != '\0')
    {
        *(destination++ + offset) = *source++;
    }
}

char *concat(char *s1, char *s2)
{
    int n_s1 = sstrlen(s1);
    int n_s2 = sstrlen(s2);

    char *p = (char *)malloc((n_s1 + n_s2 + 1) * sizeof(char));
    replace(s1, p, 0);
    replace(s2, p, n_s1);
    *(p + n_s1 + n_s2) = '\0';
    return p;
}
