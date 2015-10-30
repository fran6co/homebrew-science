class Fastflow < Formula
  desc "C++ parallel programming framework"
  homepage "http://calvados.di.unipi.it/"
  url "https://downloads.sourceforge.net/projects/mc-fastflow/files/fastflow-2.0.4.tgz"
  sha256 "4c5eda03b6aeaabda468bacb2085fdaa481ba2412138303ea0f07ce203de1a3e"

  head do
    url "http://svn.code.sf.net/p/mc-fastflow/code/"
  end

  needs :cxx11

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build

  depends_on "zeromq"

  resource "cppzmq" do
    url "https://github.com/zeromq/cppzmq/raw/05a0256d0eeea8063690fde6a156e14b70ed2280/zmq.hpp"
    sha256 "bf1c5b38911ca10bfd0826574710eb0c68fbd89b6eaa5e137c34dfbf824c080a"
  end

  def install
    ENV.cxx11

    args = std_cmake_args + %W[
      -DBUILD_TESTS:BOOL=NO
      -DBUILD_EXAMPLES:BOOL=NO
    ]

    resource("cppzmq").stage include.to_s

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install", "DESTDIR=#{prefix}"
    end
  end
end
