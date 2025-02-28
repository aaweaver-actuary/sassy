#ifndef STR_TO_INT_H
#define STR_TO_INT_H

#include <limits.h>

/**
 * @brief Convert a character-encoded number to an integer.
 *
 * This function accepts a C string that represents a number (possibly with leading zeros)
 * and returns its integer value. If the string is NULL, empty, contains invalid characters,
 * or if the value is out of range for an int, the function returns the SAS missing value,
 * defined as INT_MIN.
 *
 * @param str A pointer to a null-terminated C string representing the number.
 * @return The integer representation of the number, or INT_MIN if conversion fails.
 */
int str_to_int(const char *str);

#endif /* STR_TO_INT_H */
