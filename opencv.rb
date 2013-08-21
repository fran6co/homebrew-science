require 'formula'

class Opencv < Formula
  homepage 'http://opencv.org/'
  url 'http://sourceforge.net/projects/opencvlibrary/files/opencv-unix/2.4.6.1/opencv-2.4.6.1.tar.gz'
  sha1 'e015bd67218844b38daf3cea8aab505b592a66c0'

  option '32-bit'
  option 'with-qt',  'Build the Qt4 backend to HighGUI'
  option 'with-tbb', 'Enable parallel code in OpenCV using Intel TBB'
  option 'without-opencl', 'Disable gpu code in OpenCV using OpenCL'
  option 'with-openni', 'Enable support for OpenNI.'

  depends_on 'cmake' => :build
  depends_on 'pkg-config' => :build
  depends_on 'numpy' => :python
  depends_on :python

  depends_on 'eigen'   => :optional
  depends_on 'libtiff' => :optional
  depends_on 'jasper'  => :optional
  depends_on 'tbb'     => :optional
  depends_on 'qt'      => :optional
  depends_on 'totakke/openni/openni' if build.with? 'openni'
  depends_on :libpng

  # Can also depend on ffmpeg, but this pulls in a lot of extra stuff that
  # you don't need unless you're doing video analysis, and some of it isn't
  # in Homebrew anyway. Will depend on openexr if it's installed.

  def install
    args = std_cmake_args + %W[
      -DCMAKE_OSX_DEPLOYMENT_TARGET=
      -DWITH_CUDA=OFF
      -DBUILD_ZLIB=OFF
      -DBUILD_TIFF=OFF
      -DBUILD_PNG=OFF
      -DBUILD_JPEG=OFF
      -DBUILD_JASPER=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_PERF_TESTS=OFF
      -DPYTHON_INCLUDE_DIR='#{python.incdir}'
      -DPYTHON_LIBRARY='#{python.libdir}/lib#{python.xy}.dylib'
    ]

    if build.build_32_bit?
      args << "-DCMAKE_OSX_ARCHITECTURES=i386"
      args << "-DOPENCV_EXTRA_C_FLAGS='-arch i386 -m32'"
      args << "-DOPENCV_EXTRA_CXX_FLAGS='-arch i386 -m32'"
    end
    args << '-DWITH_QT=ON' if build.with? 'qt'
    args << '-DWITH_TBB=ON' if build.with? 'tbb'
    args << '-DWITH_OPENNI=ON' if build.with? 'openni'
    # OpenCL 1.1 is required, but Snow Leopard and older come with 1.0
    args << '-DWITH_OPENCL=OFF' if build.without? 'opencl' or MacOS.version < :lion

    args << '..'
    mkdir 'macbuild' do
      system 'cmake', *args
      system "make"
      system "make install"
    end
  end


  def caveats
    python.standard_caveats if python
  end
end
# If openni was installed using homebrew, look for it on the proper path
__END__
diff --git a/cmake/OpenCVFindOpenNI.cmake b/cmake/OpenCVFindOpenNI.cmake
index 7541868..f1455e8 100644
--- a/cmake/OpenCVFindOpenNI.cmake
+++ b/cmake/OpenCVFindOpenNI.cmake
@@ -26,8 +26,8 @@ if(WIN32)
         find_library(OPENNI_LIBRARY "OpenNI64" PATHS $ENV{OPEN_NI_LIB64} DOC "OpenNI library")
     endif()
 elseif(UNIX OR APPLE)
-    find_file(OPENNI_INCLUDES "XnCppWrapper.h" PATHS "/usr/include/ni" "/usr/include/openni" DOC "OpenNI c++ interface header")
-    find_library(OPENNI_LIBRARY "OpenNI" PATHS "/usr/lib" DOC "OpenNI library")
+    find_file(OPENNI_INCLUDES "XnCppWrapper.h" PATHS "HOMEBREW_PREFIX/include/ni" "/usr/include/ni" "/usr/include/openni" DOC "OpenNI c++ interface header")
+    find_library(OPENNI_LIBRARY "OpenNI" PATHS "HOMEBREW_PREFIX/lib" "/usr/lib" DOC "OpenNI library")
 endif()

 if(OPENNI_LIBRARY AND OPENNI_INCLUDES)
