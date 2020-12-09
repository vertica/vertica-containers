#include <iostream>
#include <string>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>

int main(const int argc, char *const argv[], char *const envp[]) {
    const char *progname = argv[0];
    const int command_arg = 2;
    const int directory_arg = 1;

    // minimal argset: 0: "wrapper", 1: directory, 2: command-to-run
    if(argc > command_arg) {
        const char *dir = argv[directory_arg];
        if(chdir(dir) < 0) {
            std::cerr << progname
                      << ": Can't chdir to "
                      << dir
                      << "; " << strerror(errno)
                      << std::endl;
            return 1;
        }
        else {
            std::cout << progname
                      << ": in directory "
                      << dir
                      << std::endl;
            char *args[argc-command_arg];
            const char *command = argv[command_arg];
            std::cout << progname
                      << ": running command "
                      << command
                      << std::endl;
            int out = 0;
            args[out++] = const_cast<char*>(command);
            for(int in = command_arg+1; in < argc && out < argc-command_arg;) {
                args[out++] = argv[in++];
            }
            args[out] = 0;

            execve(command, args, envp);

            // if we get here, execve failed
            std::cerr << progname
                      << ": Can't exec "
                      << command
                      << "; " << strerror(errno)
                      << std::endl;
            return 1;
        }
    }
    else {
        const bool debug_args = false;
        if(debug_args) {
            std::cerr << progname
                      << ": Args: ";
            for(int i = 1; i < argc; ++i) {
                std::cerr << argv[i] << " ";
            }
        }
        std::cerr << std::endl;
        std::cerr << progname
                  << ": Usage: "
                  << progname
                  << " directory command [command-args....]"
                  << std::endl;
        return 1;
    }
    return 0;
}
