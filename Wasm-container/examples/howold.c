/* just the howold function --- no need for stdlib
 *
 * compile with:
 *   clang --target=wasm64 -nostdlib -Wl,--no-entry -Wl,--export-all howold.c -o howold.wasm
 */

int howOld(int currentYear, int yearBorn) {
    int retvalue = -1;
    if(yearBorn <= currentYear) {
        retvalue = currentYear - yearBorn;
    }
    return retvalue;
}
