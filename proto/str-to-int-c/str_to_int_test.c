#ifdef UNIT_TEST
#include <assert.h>
#include <stdio.h>
#include <limits.h>
#include "str_to_int.h"

int main(void) {
    // Valid inputs.
    assert(parse_number("123") == 123);
    assert(parse_number("00123") == 123);
    assert(parse_number("-00123") == -123);
    assert(parse_number("  456  ") == 456);

    // Invalid inputs should yield the SAS missing value.
    assert(parse_number("abc") == INT_MIN);
    assert(parse_number("123abc") == INT_MIN);
    assert(parse_number("") == INT_MIN);

    // NULL pointer.
    assert(parse_number(NULL) == INT_MIN);

    printf("All C tests passed.\n");
    return 0;
}
#endif
