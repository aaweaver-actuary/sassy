#include "str_to_int.h"
#include <stdlib.h>
#include <errno.h>
#include <limits.h>
#include <ctype.h>

int str_to_int(const char *str) {
    if (str == NULL) {
        return INT_MIN;  // Return SAS missing value.
    }

    char *endptr;
    errno = 0;
    long value = strtol(str, &endptr, 10);

    // Check that at least one digit was found.
    if (str == endptr) {
        return INT_MIN;
    }

    // Skip any trailing whitespace.
    while (*endptr != '\0') {
        if (!isspace((unsigned char)*endptr)) {
            return INT_MIN;
        }
        endptr++;
    }

    // Check for overflow/underflow.
    if ((errno == ERANGE && (value == LONG_MAX || value == LONG_MIN)) ||
         value > INT_MAX || value < INT_MIN) {
        return INT_MIN;
    }
    return (int)value;
}
