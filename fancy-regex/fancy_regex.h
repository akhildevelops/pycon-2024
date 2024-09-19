void *get_regex(char *pattern);

void *get_matches(void *regex, char *data);

typedef struct matchIndex
{

    unsigned long long start;
    unsigned long long end;

} MatchIndex;

MatchIndex *next(void *matches);