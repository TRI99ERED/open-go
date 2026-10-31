#include "gnugo_ffi.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "interface.h"

FFI_PLUGIN_EXPORT int32_t
gnugo_ffi_init(int32_t boardsize, uint32_t seed)
{
  return gnugo_embedded_init(boardsize, seed);
}

FFI_PLUGIN_EXPORT int32_t
gnugo_ffi_command(const char *command, char *response, int32_t capacity)
{
  FILE *output;
#ifndef __ANDROID__
  long response_length;
  size_t bytes_read;
#else
  char *memory_output = NULL;
  size_t memory_length = 0;
#endif

  if (!command || !response || capacity <= 0)
    return -1;

  response[0] = '\0';
#ifdef __ANDROID__
  output = open_memstream(&memory_output, &memory_length);
#else
  output = tmpfile();
#endif
  if (!output)
    return -2;

  if (gnugo_embedded_command(command, output) != 0) {
    fclose(output);
#ifdef __ANDROID__
    free(memory_output);
#endif
    return -3;
  }

#ifdef __ANDROID__
  if (fflush(output) != 0) {
    fclose(output);
    free(memory_output);
    return -4;
  }

  if (!memory_output || memory_length >= (size_t) capacity) {
    fclose(output);
    free(memory_output);
    return -5;
  }

  if (fclose(output) != 0) {
    free(memory_output);
    return -6;
  }

  memcpy(response, memory_output, memory_length);
  response[memory_length] = '\0';
  free(memory_output);
  return (int32_t) memory_length;
#else
  if (fflush(output) != 0 || fseek(output, 0, SEEK_END) != 0) {
    fclose(output);
    return -4;
  }

  response_length = ftell(output);
  if (response_length < 0 || response_length >= capacity) {
    fclose(output);
    return -5;
  }

  rewind(output);
  bytes_read = fread(response, 1, (size_t) response_length, output);
  if (bytes_read != (size_t) response_length || ferror(output)) {
    fclose(output);
    return -6;
  }

  response[bytes_read] = '\0';
  fclose(output);
  return (int32_t) bytes_read;
#endif
}
