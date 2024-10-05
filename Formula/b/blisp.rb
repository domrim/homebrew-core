class Blisp < Formula
  desc "ISP tool & library for Bouffalo Labs RISC-V Microcontrollers and SoCs"
  homepage "https://github.com/pine64/blisp"
  license "MIT"
  head "https://github.com/pine64/blisp.git", branch: "master"

  stable do
    url "https://github.com/pine64/blisp/archive/refs/tags/v0.0.4.tar.gz"
    sha256 "288a8165f7dce604657f79ee8eea895cc2fa4e4676de5df9853177defd77cf78"

    # Two patches fixing installing of included header files to the includedir instead of libdir
    # will be obsolete with next release
    patch do
      url "https://github.com/pine64/blisp/commit/3b47993de763b1a78222738aefa3f5f3cb4e393d.patch?full_index=1"
      sha256 "fb31d4ec897b80795b3975cde289b1d19ac0299b15e82645e75d58cec94d5537"
    end
    patch do
      url "https://github.com/pine64/blisp/commit/2203a250e3d750bc498beae0c979f1a5b43e9e80.patch?full_index=1"
      sha256 "36b245b6599942968e1b78f352495acf75555b210defc0da973782388bcfa609"
    end
  end

  depends_on "argtable3" => :build
  depends_on "cmake" => :build
  depends_on "libserialport" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DBLISP_USE_SYSTEM_LIBRARIES=ON",
                    "-DBLISP_BUILD_CLI=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    output = shell_output("#{bin}/blisp write --chip=bl60x --reset --port COMX name_of_firmware.bin 2>&1", 4)
    assert_match "Failed to open device", output

    output = shell_output("#{bin}/blisp write --chip=bl70x name_of_firmware.bin 2>&1", 3)
    assert_match "Device not found", output

    assert_match version.to_s, shell_output("#{bin}/blisp --version")
    assert_match "Writes firmware to SPI Flash", shell_output("#{bin}/blisp write --help")
  end
end
