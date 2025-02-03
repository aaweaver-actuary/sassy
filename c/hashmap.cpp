#include "hashmap.h"
#include <cstring>
#include <algorithm>

using namespace std;

// Implementations of HashMap methods

HashMap& HashMap::Instance() {
    static HashMap instance;
    return instance;
}

std::string HashMap::sas_to_string(const char* sas_str, int sas_len) const {
    int actual_len = std::min(sas_len, 255);
    while (actual_len > 0 && sas_str[actual_len - 1] == ' ') {
        actual_len--;
    }
    return std::string(sas_str, actual_len);
}

void HashMap::insert(const char* key, int key_len, const char* value, int value_len) {
    std::string key_str = sas_to_string(key, key_len);
    std::string value_str = sas_to_string(value, value_len);
    data[key_str] = value_str;
}

int HashMap::get(const char* key, int key_len, char* buffer, int buffer_max_len) {
    std::string key_str = sas_to_string(key, key_len);
    auto it = data.find(key_str);
    if (it != data.end()) {
        int copy_len = std::min((int)it->second.size(), buffer_max_len);
        std::memcpy(buffer, it->second.data(), copy_len);
        if (copy_len < buffer_max_len)
            std::fill(buffer + copy_len, buffer + buffer_max_len, ' ');
        return copy_len;
    }
    return 0;
}

bool HashMap::exists(const char* key, int key_len) const {
    std::string key_str = sas_to_string(key, key_len);
    return data.find(key_str) != data.end();
}

void HashMap::remove(const char* key, int key_len) {
    std::string key_str = sas_to_string(key, key_len);
    data.erase(key_str);
}

// C wrapper functions
extern "C" {
    void insert(char* key, int key_len, char* value, int value_len) {
        HashMap::Instance().insert(key, key_len, value, value_len);
    }

    char* get(char* key, int key_len, char* value, int value_max_len, int* value_act_len) {
        int copied = HashMap::Instance().get(key, key_len, value, value_max_len);
        *value_act_len = copied;
        return value;
    }

    int exists(char* key, int key_len) {
        return HashMap::Instance().exists(key, key_len) ? 1 : 0;
    }

    void hm_remove(char* key, int key_len) {
        HashMap::Instance().remove(key, key_len);
    }
}