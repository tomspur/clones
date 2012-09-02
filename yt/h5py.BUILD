#!/usr/bin/env bash

cat <<EOF | patch -f | :
diff -r 84c88616af0d setup.py
--- a/setup.py  Mon Aug 27 12:31:46 2012 -0600
+++ b/setup.py  Sun Sep 02 20:28:35 2012 +0200
@@ -7,8 +7,11 @@
 
 try:
     import Cython.Compiler.Version
+    version = Cython.Compiler.Version.version
+    if version.endswith("-pre"):
+        version = version[:-4]
     vers = tuple(int(x.rstrip('+')) for
-                 x in Cython.Compiler.Version.version.split('.'))
+                 x in version.split('.'))
     if vers < (0,13):
         raise ImportError
     from Cython.Distutils import build_ext
EOF

cd h5py
python api_gen.py
cd ..

CFLAGS="$CFLAGS -I$VIRTUAL_ENV/include -L$VIRTUAL_ENV/lib" \
    python setup.py build
