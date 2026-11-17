# typed: false
# frozen_string_literal: true

class Antfly < Formula
  desc "Native Zig AntflyDB runtime"
  homepage "https://docs.antfly.io"
  version "0.3.1"
  # Recover from older formulae that inferred version 64 from arm64 archives.
  version_scheme 1
  license "Apache-2.0"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://releases.antfly.io/antfly/v0.3.1/antfly_0.3.1_Darwin_arm64.tar.gz"
      sha256 "e5de808aff800022c1cd1c479fb032d81966d14bdbd339f15fda00e1091b3046"
    else
      odie "antfly supports Apple Silicon macOS only"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://releases.antfly.io/antfly/v0.3.1/antfly_0.3.1_Linux_arm64_gnu.tar.gz"
      sha256 "e37e83225a42737120b0d1f7dac572890b9bf399436ba12eb48da0a2cc38e681"
    else
      url "https://releases.antfly.io/antfly/v0.3.1/antfly_0.3.1_Linux_x86_64_gnu.tar.gz"
      sha256 "fb5ef02974ae66a3869597ae1593bb474021c543340f96eb52f466a9a166fc81"
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
