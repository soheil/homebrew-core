  url "https://github.com/chapel-lang/chapel/releases/download/2.2.0/chapel-2.2.0.tar.gz"
  sha256 "bb16952a87127028031fd2b56781bea01ab4de7c3466f7b6a378c4d8895754b6"
    sha256 arm64_sequoia: "bf699c9806375fabf1b6287cd9a5f95d2f207893b6e13715449f039974b23f64"
    sha256 arm64_sonoma:  "b7d3d45beff719677abe1837743c7c49be92e0f1a9f76b3dcfa976e85b64fc01"
    sha256 arm64_ventura: "aaa552f946f72c9455ca9ecda1be4f8cdaf1c8e41cb5dadcbae35e86d5e36fc5"
    sha256 sonoma:        "7e131ad39120b86823f32d442a2c2e6f7f5d8c1d0b3552b2baf519b94f798a9d"
    sha256 ventura:       "54975ba802a1d47a2be81d43506d04c6de12625f0b2894be5cf300e28433e622"
    sha256 x86_64_linux:  "b5c76ea840dd2cf224576761c821db3c8fafcf9fd50315ee11f8367024a7f853"
      rm_r("third-party/gasnet/gasnet-src/")
      rm_r("third-party/libfabric/libfabric-src/")
      rm_r("third-party/fltk/fltk-1.3.8-source.tar.gz")
      rm_r("third-party/libunwind/libunwind-src/")
      rm_r("third-party/qthread/qthread-src/")