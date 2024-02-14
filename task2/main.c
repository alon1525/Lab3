#define SYS_WRITE 4
#define STDOUT 1
#define SYS_OPEN 5
#define BUF_SIZE 8192

extern int system_call();

void printchar(char c) {
    system_call(SYS_WRITE, STDOUT, c, 1);
}

void print_file(const char *filename) {
    int fd = system_call(SYS_OPEN, filename, 0, 0);
    if (fd < 0) {
        return;
    }

    char buf[BUF_SIZE];
    int bytes_read;
    while ((bytes_read = system_call(3, fd, buf, BUF_SIZE)) > 0) {
        int bytes_written = 0;
        while (bytes_written < bytes_read) {
            bytes_written += system_call(SYS_WRITE, STDOUT, buf + bytes_written, bytes_read - bytes_written);
        }
    }

    system_call(6, fd);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        return 1;
    }

    print_file(argv[1]);
    return 0;
}