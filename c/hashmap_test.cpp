#include <iostream>
#include <cstring>
#include <cassert>
#include "hashmap.h"

int main() {
    // Test insert and exists
    char key1[] = "key1   ";
    char value1[] = "value1   ";
    insert(key1, strlen(key1), value1, strlen(value1));
    assert(exists(key1, strlen(key1)) == 1);

    // Test get function for existing key
    char buffer[256] = {0};
    int actual_len = 0;
    get(key1, strlen(key1), buffer, sizeof(buffer), &actual_len);
    // Ensure null termination for comparison
    buffer[actual_len] = '\0';
    assert(std::strcmp(buffer, "value1") == 0);

    // Test exists for non-existing key
    char key2[] = "nonexistent";
    assert(exists(key2, strlen(key2)) == 0);

    // Optional: test hm_remove
    hm_remove(key1, strlen(key1));
    assert(exists(key1, strlen(key1)) == 0);

    std::cout << "All tests passed." << std::endl;
    return 0;
}
