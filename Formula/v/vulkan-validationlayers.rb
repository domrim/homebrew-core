class VulkanValidationlayers < Formula
  desc "Vulkan layers that enable developers to verify correct use of the Vulkan API"
  homepage "https://github.com/KhronosGroup/Vulkan-ValidationLayers"
  license "Apache-2.0"
  head "https://github.com/KhronosGroup/Vulkan-ValidationLayers.git", branch: "main"

  stable do
    url "https://github.com/KhronosGroup/Vulkan-ValidationLayers/archive/refs/tags/v1.3.261.tar.gz"
    sha256 "ab769d9d7550e1636c9309387a7e53be5ba89f0b19f810bb40caa1b6eaefe8ee"

    # revert vulkan-utility-libraries dependency, remove in next release
    patch do
      url "https://github.com/KhronosGroup/Vulkan-ValidationLayers/commit/e6bdb8d71409a96a4174589ea195d0dc1e920625.patch?full_index=1"
      sha256 "5bc8e5bbae533f4d2586055fd4eccc93c2e4d7bccf5faea1fca8bae9f332246c"
    end
  end

  bottle do
    sha256 cellar: :any,                 arm64_ventura:  "a344fc4bccbf4505caa2a700a21f46e147a9e79f6876809b40967fb169d8fd37"
    sha256 cellar: :any,                 arm64_monterey: "a2744ddfcec7ddc534e933aec54a3a361bd7c78a5943db20ff5c566400341bb1"
    sha256 cellar: :any,                 arm64_big_sur:  "9931def5297dce6d87327d64093555a060132ba7d98d54da3e8afba43c250fb0"
    sha256 cellar: :any,                 ventura:        "3f6dc678afd4b1355875746df32e6bcc7eda0c83e7d8a3b92e573564f18af2b5"
    sha256 cellar: :any,                 monterey:       "65c790510017b6ae55e0666a26b00bcbc52b75c9ecc1ed2d420bc3abe7d5d64b"
    sha256 cellar: :any,                 big_sur:        "6b3a8ab678a607bd891ab85acece74fd8f91139de5812ebf70fe49b19eee4067"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "e834d1d737fbc101412b4c784435bc3ae1611deee28a3c7299559453efee41f5"
  end

  depends_on "cmake" => :build
  depends_on "googletest" => :build
  depends_on "python@3.11" => :build
  depends_on "vulkan-loader" => :test
  depends_on "vulkan-tools" => :test
  depends_on "glslang"
  depends_on "spirv-headers"
  depends_on "vulkan-headers"

  on_linux do
    depends_on "libx11" => :build
    depends_on "libxcb" => :build
    depends_on "libxrandr" => :build
    depends_on "pkg-config" => :build
    depends_on "wayland" => :build
  end

  # https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/v#{version}/scripts/known_good.json#L57
  resource "SPIRV-Tools" do
    url "https://github.com/KhronosGroup/SPIRV-Tools.git",
        revision: "e553b884c7c9febaa4e52334f683641fb5f196a0"
  end

  def install
    resource("SPIRV-Tools").stage do
      system "cmake", "-S", ".", "-B", "build",
                      "-DSPIRV-Headers_SOURCE_DIR=#{Formula["spirv-headers"].prefix}",
                      "-DSPIRV_WERROR=OFF",
                      "-DSPIRV_SKIP_TESTS=ON",
                      "-DSPIRV_SKIP_EXECUTABLES=ON",
                      *std_cmake_args(install_prefix: buildpath/"third_party/SPIRV-Tools")
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end

    args = [
      "-DGLSLANG_INSTALL_DIR=#{Formula["glslang"].prefix}",
      "-DSPIRV_HEADERS_INSTALL_DIR=#{Formula["spirv-headers"].prefix}",
      "-DSPIRV_TOOLS_INSTALL_DIR=#{buildpath}/third_party/SPIRV-Tools",
      "-DVULKAN_HEADERS_INSTALL_DIR=#{Formula["vulkan-headers"].prefix}",
      "-DBUILD_LAYERS=ON",
      "-DBUILD_LAYER_SUPPORT_FILES=ON",
      "-DBUILD_TESTS=OFF",
      "-DUSE_ROBIN_HOOD_HASHING=OFF",
    ]
    if OS.linux?
      args += [
        "-DBUILD_WSI_XCB_SUPPORT=ON",
        "-DBUILD_WSI_XLIB_SUPPORT=ON",
        "-DBUILD_WSI_WAYLAND_SUPPORT=ON",
      ]
    end
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  def caveats
    <<~EOS
      In order to use this layer in a Vulkan application, you may need to place it in the environment with
        export VK_LAYER_PATH=#{opt_share}/vulkan/explicit_layer.d
    EOS
  end

  test do
    ENV.prepend_path "VK_LAYER_PATH", share/"vulkan/explicit_layer.d"
    ENV["VK_ICD_FILENAMES"] = Formula["vulkan-tools"].lib/"mock_icd/VkICD_mock_icd.json"

    expected = <<~EOS
      Instance Layers: count = 1
      --------------------------
      VK_LAYER_KHRONOS_validation Khronos Validation Layer #{version}  version 1
    EOS
    actual = shell_output("vulkaninfo --summary")
    assert_match expected, actual
  end
end
