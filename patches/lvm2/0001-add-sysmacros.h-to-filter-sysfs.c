--- a/lib/filters/filter-sysfs.c	2021-08-13 14:07:25.761101198 +0000
+++ b/lib/filters/filter-sysfs.c	2021-08-13 03:57:01.817585951 +0000
@@ -18,6 +18,7 @@
 #ifdef __linux__

 #include <dirent.h>
+#include <sys/sysmacros.h>

 static int _locate_sysfs_blocks(const char *sysfs_dir, char *path, size_t len,
 				unsigned *sysfs_depth)
