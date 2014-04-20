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

typedef int (*uname_t) (struct utsname * buf);

static void *get_libc_func(const char *funcname)
{
  void *func;
  char *error;

  func = dlsym(RTLD_NEXT, funcname);
  if ((error = dlerror()) != NULL) {
    fprintf(stderr, "Can't locate libc function `%s' error: %s", funcname, error);
    _exit(EXIT_FAILURE);
  }
  return func;
}

int uname(struct utsname *buf)
{
  int ret;
  char *env = NULL;
  uname_t real_uname = (uname_t) get_libc_func("uname");

  ret = real_uname((struct utsname *) buf);
  strncpy(buf->release, ((env = getenv("UTS_RELEASE")) == NULL) ? UTS_RELEASE : env, 65);
  return ret;
}
