# typed: false
# frozen_string_literal: true

class Antfly < Formula
  desc "Native Zig AntflyDB runtime"
  homepage "https://docs.antfly.io"
  version "0.3.0"
  # Recover from older formulae that inferred version 64 from arm64 archives.
  version_scheme 1
  license "Apache-2.0"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://releases.antfly.io/antfly/v0.3.0/antfly_0.3.0_Darwin_arm64.tar.gz"
      sha256 "ae1cf137fae51ed79e6ebee5d4da4e22e48bce79f74e4a93cc9782a942b4b51b"
    else
      odie "antfly supports Apple Silicon macOS only"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://releases.antfly.io/antfly/v0.3.0/antfly_0.3.0_Linux_arm64_gnu.tar.gz"
      sha256 "602c950c976453e53197ba427eae947bf5bcaaf5697a5fed8aa1b7fb99f4195e"
    else
      url "https://releases.antfly.io/antfly/v0.3.0/antfly_0.3.0_Linux_x86_64_gnu.tar.gz"
      sha256 "3ac909e8a4ba5dee9187a1a427e86d347eb9d18861e68ce3a611dffa03bfeedb"
    end
  end

  def install
    bin.install "antfly"
    include.install Dir["include/*"] if Dir.exist?("include")
    lib.install Dir["lib/*"] if Dir.exist?("lib")
    (share/"antfly").install Dir["share/antfly/*"] if Dir.exist?("share/antfly")
    bash_completion.install "completions/antfly.bash" => "antfly"
    zsh_completion.install "completions/antfly.zsh" => "_antfly"
    fish_completion.install "completions/antfly.fish"
  end

  service do
    run [opt_bin/"antfly", "standalone", "--data-dir", var/"lib/antfly"]
    keep_alive true
    working_dir var/"lib/antfly"
    log_path var/"log/antfly.log"
    error_log_path var/"log/antfly.err.log"
  end

  def post_install
    (var/"lib/antfly").mkpath
  end

  test do
    system "#{bin}/antfly", "--help"
    (testpath/"smoke.c").write <<~'C'
      #include <antfly.h>
      #include <stdio.h>
      int main(void) {
        uint32_t abi = antfly_abi_version();
        #ifdef ANTFLY_ABI_VERSION
        if (abi != ANTFLY_ABI_VERSION) {
          fprintf(stderr, "libantfly ABI %u differs from header ABI %u\n", abi, ANTFLY_ABI_VERSION);
          return 1;
        }
        #else
        /* Historical release headers predate the ABI declaration. */
        if (abi != 1 && abi != 2 && abi != 3) {
          fprintf(stderr, "unsupported legacy libantfly ABI %u\n", abi);
          return 1;
        }
        #endif
        #ifdef ANTFLY_ABI_VERSION
        if (antfly_open_options_size() != sizeof(antfly_open_options)) {
          fprintf(stderr, "libantfly open options size differs from header\n");
          return 2;
        }
        #endif
        antfly_db *db = NULL;
        antfly_error_code code = antfly_lite_create("smoke.aflite", &db);
        if (code != ANTFLY_OK) {
          #ifdef ANTFLY_ABI_VERSION
          fprintf(stderr, "antfly_lite_create: %s: %s\n", antfly_error_code_name(code), antfly_last_error_detail());
          #else
          fprintf(stderr, "antfly_lite_create failed with error %u\n", (unsigned)code);
          #endif
          return 3;
        }
        antfly_db_close(db);
        return 0;
      }
    C
    system ENV.cc, "smoke.c", "-I#{include}", "-L#{lib}", "-lantfly",
           "-Wl,-rpath,#{lib}", "-o", "smoke"
    system "./smoke"
  end

  def caveats
    <<~EOS
      antfly is now the native Zig runtime.

      Create and verify a portable backup before upgrading across storage-format
      changes, and restore into a fresh data directory when rollback is needed.

      Start the local single-node service with:
        brew services start antflydb/taps/antfly
    EOS
  end
end
