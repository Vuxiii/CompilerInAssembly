#include <stdio.h>
#include <sys/types.h>



uint hash(char *identifier) {
    uint M = 100; // Size of table
    uint W = 2*2*2*2*2*2*2*2;
    uint a = 255;
    uint val = 0;
    for ( char *c = identifier; *c != '\0'; ++c ) {
        val += *c;
    }
    val ^= val >> (W-M);

    return (a*val) >> (W-M);
}

int main() {
    char *var = "some_func";
    char *var2 = "some_func1";
    char *var4 = "2";
    char *var3 = "som2e_func";

    printf("The hash-value for '%s', is %d\n", var, hash(var));
    printf("The hash-value for '%s', is %d\n", var2, hash(var));
    printf("The hash-value for '%s', is %d\n", var3, hash(var));
    printf("The hash-value for '%s', is %d\n", var4, hash(var));
    return 0;
}