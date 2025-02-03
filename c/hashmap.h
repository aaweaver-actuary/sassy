#ifndef HASHMAP_H
#define HASHMAP_H

#include <string>
#include <map>
#include <algorithm>

class HashMap {
public:
    // Insert a key-value pair
    void insert(const char* key, int key_len, const char* value, int value_len);
    // Get value into provided buffer; returns number of characters copied (0 if key not found)
    int get(const char* key, int key_len, char* buffer, int buffer_max_len);
    // Check existence
    bool exists(const char* key, int key_len) const;
    // Remove key
    void remove(const char* key, int key_len);
    // Singleton accessor
    static HashMap& Instance();
private:
    std::map<std::string, std::string> data;
    std::string sas_to_string(const char* sas_str, int sas_len) const;
};

#ifdef __cplusplus
extern "C" {
#endif

// C interface wrappers (note: 'hm_remove' is renamed to avoid conflict with stdio.h)
void insert(char* key, int key_len, char* value, int value_len);
char* get(char* key, int key_len, char* value, int value_max_len, int* value_act_len);
int exists(char* key, int key_len);
void hm_remove(char* key, int key_len);

#ifdef __cplusplus
}
#endif

#endif // HASHMAP_H
