#define SYS_WRITE 4
#define STDOUT 1
#define SYS_OPEN 5
#define SYS_SEEK 19
#define SEEK_SET 0
#define BUF_SIZE 8192
#define SYS_EXIT 60
#define SYS_READ 0
#define SYS_CLOSE 3
#define O_RDONLY 00
#define O_RDWR 2
#include "dirent.h"

#ifndef UTIL_H
#define UTIL_H

int strncmp(const char *str1, const char *str2, unsigned int n);
unsigned int strlen(const char *str);

#endif /* UTIL_H */

extern int system_call();
extern void infector(char *path);

struct linux_dirent {
    unsigned long d_ino;    /* Inode number */
    unsigned long d_off;    /* Offset to next linux_dirent */
    unsigned short d_reclen; /* Length of this linux_dirent */
    char d_name[];           /* Filename (null-terminated) */
    /* length is actually (d_reclen - 2 -
                            offsetof(struct linux_dirent, d_name)) */
};

void printFileContent(const char *filename) {
    int file = system_call(SYS_OPEN, filename,O_RDONLY);

    if (file < 0) {
        system_call(0x55);
    }

    char buffer[BUF_SIZE] = {0};
    int bytes_read = system_call(SYS_READ, file, buffer, BUF_SIZE);
    
    if (bytes_read < 0) {
        system_call(SYS_CLOSE, file);
        system_call(0x55);
    }

    system_call(SYS_WRITE, STDOUT, buffer, BUF_SIZE);
    system_call(SYS_WRITE, STDOUT, "\n", 1);

    system_call(SYS_CLOSE, file);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        system_call(0x55);
    }
    char* file;
    char *filename = argv[1];
    if (strncmp(argv[1], "-a", 2) != 0) {
        printFileContent(filename);
    }
    else
    {
        file = filename + 2;
        infector(file);
        system_call(SYS_WRITE, STDOUT, file, strlen(file));
        system_call(SYS_WRITE, STDOUT, " VIRUS ATTACHED\n", 16);
    }

    return 0;
}