class Adios2 < Formula
  desc "Next generation of ADIOS developed in the Exascale Computing Program"
  homepage "https://adios2.readthedocs.io"
  license "Apache-2.0"
  head "https://github.com/ornladios/ADIOS2.git", branch: "master"

  stable do
    url "https://github.com/ornladios/ADIOS2/archive/refs/tags/v2.10.0.tar.gz"
    sha256 "e5984de488bda546553dd2f46f047e539333891e63b9fe73944782ba6c2d95e4"

    # fix pugixml target name
    # upstream patch ref, https://github.com/ornladios/ADIOS2/pull/4135
    # https://github.com/ornladios/ADIOS2/pull/4142
    patch :DATA
  end

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 arm64_sonoma:   "adae563be0e6a56fec81f3d396ad4611b818c70a7acc54be504b1a3b0896e652"
    sha256 arm64_ventura:  "283d482432e189fe6cb1a302089e2615e49a12bfac57db69f087efe80290eae9"
    sha256 arm64_monterey: "e28f7eb517b74faaefb469e0b7bca433a7f68f04e0bde43743a866f8d3e3effc"
    sha256 sonoma:         "7933ca4cad6d0c75fa5bf2b7caf4f0675980880c4d259bf31e7294be03d75433"
    sha256 ventura:        "4a90152c29da3dcb1b329191b3bdb783eb11730b3014864080d93005fdc17534"
    sha256 monterey:       "e883fb195102fcb4e142baee668cb5532bfb0aec8413e67d35d28575915dd2a4"
    sha256 x86_64_linux:   "50dab40f7ef2a78b751fc532b74ee32d0c28a0636e1fa5c81fe59450c4806e55"
  end

  depends_on "cmake" => :build
  depends_on "nlohmann-json" => :build
  depends_on "c-blosc"
  depends_on "gcc" # for gfortran
  depends_on "libfabric"
  depends_on "libpng"
  depends_on "libsodium"
  depends_on "mpi4py"
  depends_on "numpy"
  depends_on "open-mpi"
  depends_on "pugixml"
  depends_on "pybind11"
  depends_on "python@3.12"
  depends_on "yaml-cpp"
  depends_on "zeromq"

  uses_from_macos "bzip2"

  on_macos do
    depends_on "llvm" => :build if DevelopmentTools.clang_build_version == 1400
  end

  # clang: error: unable to execute command: Segmentation fault: 11
  # clang: error: clang frontend command failed due to signal (use -v to see invocation)
  # Apple clang version 14.0.0 (clang-1400.0.29.202)
  fails_with :clang if DevelopmentTools.clang_build_version == 1400

  def python3
    "python3.12"
  end

  def install
    ENV.llvm_clang if DevelopmentTools.clang_build_version == 1400

    # fix `include/adios2/common/ADIOSConfig.h` file audit failure
    inreplace "source/adios2/common/ADIOSConfig.h.in" do |s|
      s.gsub! ": @CMAKE_C_COMPILER@", ": #{ENV.cc}"
      s.gsub! ": @CMAKE_CXX_COMPILER@", ": #{ENV.cxx}"
    end

    args = %W[
      -DADIOS2_USE_Blosc=ON
      -DADIOS2_USE_BZip2=ON
      -DADIOS2_USE_DataSpaces=OFF
      -DADIOS2_USE_Fortran=ON
      -DADIOS2_USE_HDF5=OFF
      -DADIOS2_USE_IME=OFF
      -DADIOS2_USE_MGARD=OFF
      -DADIOS2_USE_MPI=ON
      -DADIOS2_USE_PNG=ON
      -DADIOS2_USE_Python=ON
      -DADIOS2_USE_SZ=OFF
      -DADIOS2_USE_ZeroMQ=ON
      -DADIOS2_USE_ZFP=OFF
      -DCMAKE_DISABLE_FIND_PACKAGE_BISON=TRUE
      -DCMAKE_DISABLE_FIND_PACKAGE_CrayDRC=TRUE
      -DCMAKE_DISABLE_FIND_PACKAGE_FLEX=TRUE
      -DCMAKE_DISABLE_FIND_PACKAGE_LibFFI=TRUE
      -DCMAKE_DISABLE_FIND_PACKAGE_NVSTREAM=TRUE
      -DPython_EXECUTABLE=#{which(python3)}
      -DCMAKE_INSTALL_PYTHONDIR=#{prefix/Language::Python.site_packages(python3)}
      -DADIOS2_BUILD_TESTING=OFF
      -DADIOS2_BUILD_EXAMPLES=OFF
      -DADIOS2_USE_EXTERNAL_DEPENDENCIES=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    (pkgshare/"test").install "examples/hello/bpWriter/bpWriter.cpp"
    (pkgshare/"test").install "examples/hello/bpWriter/bpWriter.py"
  end

  test do
    adios2_config_flags = Utils.safe_popen_read(bin/"adios2-config", "--cxx").chomp.split
    system "mpic++", pkgshare/"test/bpWriter.cpp", *adios2_config_flags
    system "./a.out"
    assert_predicate testpath/"myVector_cpp.bp", :exist?

    system python3, "-c", "import adios2"
    system python3, pkgshare/"test/bpWriter.py"
    assert_predicate testpath/"bpWriter-py.bp", :exist?
  end
end

__END__
diff --git a/source/adios2/toolkit/remote/CMakeLists.txt b/source/adios2/toolkit/remote/CMakeLists.txt
index a739e1a..fdea6ec 100644
--- a/source/adios2/toolkit/remote/CMakeLists.txt
+++ b/source/adios2/toolkit/remote/CMakeLists.txt
@@ -6,15 +6,11 @@
 if (NOT ADIOS2_USE_PIP)
   add_executable(adios2_remote_server ./remote_server.cpp remote_common.cpp)

-  target_link_libraries(adios2_remote_server PUBLIC EVPath::EVPath adios2_core adios2sys
-    PRIVATE $<$<PLATFORM_ID:Windows>:shlwapi>)
+  target_link_libraries(adios2_remote_server
+                        PUBLIC EVPath::EVPath adios2_core adios2sys
+                        PRIVATE adios2::thirdparty::pugixml $<$<PLATFORM_ID:Windows>:shlwapi>)

-  get_property(pugixml_headers_path
-    TARGET pugixml
-    PROPERTY INTERFACE_INCLUDE_DIRECTORIES
-  )
-
-  target_include_directories(adios2_remote_server PRIVATE ${PROJECT_BINARY_DIR} ${pugixml_headers_path})
+  target_include_directories(adios2_remote_server PRIVATE ${PROJECT_BINARY_DIR})

   set_property(TARGET adios2_remote_server PROPERTY OUTPUT_NAME adios2_remote_server${ADIOS2_EXECUTABLE_SUFFIX})
   install(TARGETS adios2_remote_server EXPORT adios2
diff --git a/source/utils/CMakeLists.txt b/source/utils/CMakeLists.txt
index 30dd484..01f5f93 100644
--- a/source/utils/CMakeLists.txt
+++ b/source/utils/CMakeLists.txt
@@ -13,17 +13,11 @@ configure_file(
 add_executable(bpls ./bpls/bpls.cpp)
 target_link_libraries(bpls
                       PUBLIC adios2_core adios2sys
-                      PRIVATE $<$<PLATFORM_ID:Windows>:shlwapi>)
-
-get_property(pugixml_headers_path
-  TARGET pugixml
-  PROPERTY INTERFACE_INCLUDE_DIRECTORIES
-)
+                      PRIVATE adios2::thirdparty::pugixml $<$<PLATFORM_ID:Windows>:shlwapi>)

 target_include_directories(bpls PRIVATE
   ${PROJECT_BINARY_DIR}
   ${PROJECT_SOURCE_DIR}/bindings/C
-  ${pugixml_headers_path}
 )

 set_property(TARGET bpls PROPERTY OUTPUT_NAME bpls${ADIOS2_EXECUTABLE_SUFFIX})
