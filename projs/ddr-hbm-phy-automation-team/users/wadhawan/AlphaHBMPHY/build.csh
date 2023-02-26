#!/bin/csh
##gcc -g gds2gdt_wip.C -O -o gds2gdt_wip.Linux -I. -L. -L/usr/lib64 -lstdc++ *.o -Wreturn-type -Wswitch -Wcomment -Wformat -Wchar-subscripts -Wparentheses -Wpointer-arith -Wcast-qual -Woverloaded-virtual -Wno-write-strings /usr/lib64/libm.so -Wno-deprecated

#gcc -g alphaGdsPinInfo.C -O -o alphaGdsPinInfo.Linux -I. -L. -L/usr/lib64 -lstdc++ *.o -Wreturn-type -Wswitch -Wcomment -Wformat -Wchar-subscripts -Wparentheses -Wpointer-arith -Wcast-qual -Woverloaded-virtual -Wno-write-strings /usr/lib64/libm.so -Wno-deprecated

##  For best all-around runnability, needs to be compiled on a machine with libm.a, allowing static linking.
##  Within snps, only rh5 machines appear to have this file.  If compiled on a rh6 machine, it will likely use libm.so, dynamically linked
##  and probably will not run on a rh5 machine.

set EXTRA_LIBS="-L."
set LIBDIR=""
if (`uname -m` == "x86_64") then #for x86_64
  set LIBDIRS=(/usr/lib64 /usr/lib/x86_64-linux-gnu)
else
  set LIBDIRS=(/usr/lib /lib/i386-linux-gnu)
endif
foreach dirName ($LIBDIRS)
#  echo "checking if $dirName is valid"
  if ("$LIBDIR" == "") then
    if ((-e "$dirName/libm.a") || (-e "$dirName/libm.so")) then
      set LIBDIR=$dirName
    endif
  endif
  if (-d $dirName) then
    set EXTRA_LIBS="$EXTRA_LIBS -L$dirName"
  endif
end

set mathLibStatic="-lm $LIBDIR/libm.a -static" #prefer static version
if (! -e "$LIBDIR/libm.a") then
#  echo "Did not find static math lib. Will try to use dynamically linked version"
  set mathLibStatic="$LIBDIR/libm.so"
endif


gcc  \
    -g ./alphaCheckHbmPhyInt.C \
    -O \
    -o ./alphaCheckHbmPhyInt \
    -I. \
    -L. \
    -L/usr/lib64 \
    -lstdc++   \
    -Wreturn-type \
    -Wswitch \
    -Wcomment \
    -Wformat \
    -Wchar-subscripts \
    -Wparentheses \
    -Wpointer-arith \
    -Wcast-qual \
    -Woverloaded-virtual \
    -Wno-write-strings \
    $mathLibStatic \
    -Wno-deprecated
