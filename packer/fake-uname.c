#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/syslog.h>
#include <sys/utsname.h>

#ifndef UTS_RELEASE
#define UTS_RELEASE "0.0.0"
#endif

#ifndef RTLD_NEXT
#define RTLD_NEXT      ((void *) -1l)
#endif

#define SYMBOL_EXPORT __attribute__((visibility("default")))

typedef int uname_func(struct utsname *buf);

static void *get_libc_func(const char *funcname)
{
  void *func;
  char *error;

  /* Clear any previous errors. */
  dlerror();
  func = dlsym(RTLD_NEXT, funcname);
  error = dlerror();
  if (error != NULL) {
    fprintf(stderr, "Cannot locate libc function '%s' error: %s",
            funcname, error);
    _exit(EXIT_FAILURE);
  }
  return func;
}

int SYMBOL_EXPORT uname(struct utsname *buf)
{
  static uname_func *real_uname;
  const char *release;
  int ret;

  if (real_uname == NULL)
    real_uname = (uname_func *)get_libc_func("uname");

  ret = real_uname(buf);
  if (ret < 0)
    return ret;

  release = getenv("UTS_RELEASE");
  if (release == NULL)
    release = UTS_RELEASE;
  strncpy(buf->release, release, sizeof(buf->release) - 1);
  buf->release[sizeof(buf->release) - 1] = '\0';

  return ret;
}
