#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

FFI_PLUGIN_EXPORT int32_t gnugo_ffi_init(int32_t boardsize, uint32_t seed);
FFI_PLUGIN_EXPORT int32_t gnugo_ffi_command(const char *command,
					    char *response,
					    int32_t capacity);
