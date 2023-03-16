unsigned long long fib(unsigned long long a) {
    unsigned long long i;
    unsigned long long prev = 1;
    unsigned long long cur = 1;;
    for(i = 2; i < a; i++) {
        unsigned long long tmp = cur;
        cur = cur + prev;
        prev = tmp;
    }
    return cur;
}
