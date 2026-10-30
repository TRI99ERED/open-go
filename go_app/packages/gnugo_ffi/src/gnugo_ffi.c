#include "gnugo_ffi.h"

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
  long response_length;
  size_t bytes_read;

  if (!command || !response || capacity <= 0)
    return -1;

  response[0] = '\0';
  output = tmpfile();
  if (!output)
    return -2;

  if (gnugo_embedded_command(command, output) != 0) {
    fclose(output);
    return -3;
  }

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
}
