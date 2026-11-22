// The few MediaInfoLib C functions Video Info uses (UTF-8 "A" variants from MediaInfoDLL.cpp, statically linked).
#include <stddef.h>
void *MediaInfoA_New(void);
void MediaInfoA_Delete(void *handle);
size_t MediaInfoA_Open(void *handle, const char *file);
void MediaInfoA_Close(void *handle);
const char *MediaInfoA_Option(void *handle, const char *option, const char *value);
const char *MediaInfoA_Inform(void *handle, size_t reserved);
