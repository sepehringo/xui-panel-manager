#include <stdio.h>
#include <stdlib.h>
#define n 4
#define k 2
#define B[n][k]

int bin2(int , int);
void printArray(int*, int , int);
int min(int a, int b)
{
    return (a > b?a: b);
}


int main()
{
    printArray(bin2(n, k), n, k);
}

int bin2(int n, int k)
{
    int i, j;
 

    for (i = 0; i <= n; i++)
        for (j = 0; j <= min(i, k); j++)
        {
            if (j == 0 || j == i)
                B[i][j] = 1;
            else
                B[i][j] = B[i - 1][j - 1] + B[i - 1][j];
        }
        return B[n][k];
}

void printArray(int *a, int m , int n)
{
    for (int i = 0; i < m; i++)
    {    printf("\n");
        for (int j = 0; j < n; j++)
        {
            printf("%d\t", *(a + i*j + j));
        }
    }
}