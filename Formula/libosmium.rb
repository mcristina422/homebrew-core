class Libosmium < Formula
  desc "Fast and flexible C++ library for working with OpenStreetMap data"
  homepage "https://osmcode.org/libosmium/"
  url "https://github.com/osmcode/libosmium/archive/v2.15.1.tar.gz"
  sha256 "4c0fe0146aee20423d9526e88f205fe442257fdf26df19225e2bde6084bad0ef"

  bottle do
    cellar :any_skip_relocation
    rebuild 1
    sha256 "51876fb1bc9ba3495dbf098737e891296d3c9aca69a1100b350fe75c078a5c4a" => :mojave
    sha256 "c6d4232ba9c320f939116309788b3a8dec335531294cc683d7fc043ba1232ac0" => :high_sierra
    sha256 "c6d4232ba9c320f939116309788b3a8dec335531294cc683d7fc043ba1232ac0" => :sierra
  end

  depends_on "boost" => :build
  depends_on "cmake" => :build

  resource "protozero" do
    url "https://github.com/mapbox/protozero/archive/v1.6.3.tar.gz"
    sha256 "c5d3c71f5fb56d867ff0536e55cd7a3f2eb0d09f6ebbf636b0fde4f0e12552f5"
  end

  def install
    resource("protozero").stage { libexec.install "include" }
    system "cmake", ".", "-DINSTALL_GDALCPP=ON",
                         "-DINSTALL_UTFCPP=ON",
                         "-DPROTOZERO_INCLUDE_DIR=#{libexec}/include",
                         *std_cmake_args
    system "make", "install"
  end

  test do
    (testpath/"test.osm").write <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <osm version="0.6" generator="handwritten">
        <node id="1" lat="0.001" lon="0.001" user="Dummy User" uid="1" version="1" changeset="1" timestamp="2015-11-01T19:00:00Z"></node>
        <node id="2" lat="0.002" lon="0.002" user="Dummy User" uid="1" version="1" changeset="1" timestamp="2015-11-01T19:00:00Z"></node>
        <way id="1" user="Dummy User" uid="1" version="1" changeset="1" timestamp="2015-11-01T19:00:00Z">
          <nd ref="1"/>
          <nd ref="2"/>
          <tag k="name" v="line"/>
        </way>
        <relation id="1" user="Dummy User" uid="1" version="1" changeset="1" timestamp="2015-11-01T19:00:00Z">
          <member type="node" ref="1" role=""/>
          <member type="way" ref="1" role=""/>
        </relation>
      </osm>
    EOS

    (testpath/"test.cpp").write <<~EOS
      #include <cstdlib>
      #include <iostream>
      #include <osmium/io/xml_input.hpp>

      int main(int argc, char* argv[]) {
        osmium::io::File input_file{argv[1]};
        osmium::io::Reader reader{input_file};
        while (osmium::memory::Buffer buffer = reader.read()) {}
        reader.close();
      }
    EOS

    system ENV.cxx, "-std=c++11", "-stdlib=libc++", "-lexpat", "-o", "libosmium_read", "test.cpp"
    system "./libosmium_read", "test.osm"
  end
end
