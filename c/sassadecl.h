
#ifndef SASSADECL_H
#define SASSADECL_H

#ifdef __cplusplus
extern "C" {
#endif

// Pure C interface for SAS PROC PROTO
void insert(char* key, int key_len, char* value, int value_len);
char* get(char* key, int key_len, char* value, int value_max_len, int* value_act_len);
int exists(char* key, int key_len);
void hm_remove(char* key, int key_len);

#ifdef __cplusplus
}
#endif

#endif // SASSADECL_H