# typed: false
# frozen_string_literal: true

class Antfly < Formula
  desc "Native Zig AntflyDB runtime"
  homepage "https://docs.antfly.io"
  version "0.2.1"
  revision 1
  # Recover from older formulae that inferred version 64 from arm64 archives.
  version_scheme 1
  license "Elastic-2.0"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/antflydb/homebrew-taps/releases/download/antfly-v0.2.1-homebrew.1/antfly_0.2.1_Darwin_arm64_homebrew_1.tar.gz"
      sha256 "5726eebf7fccd0bdf04da470b431953fab4b748dcd1fe1f7608d14db5d5f3f48"
    else
      odie "antfly supports Apple Silicon macOS only"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://releases.antfly.io/antfly/v0.2.1/antfly_0.2.1_Linux_arm64_gnu.tar.gz"
      sha256 "b66c9684e2998d5c4fea79b15dc80ec317fbeeaf9188e5d64f463895a2924884"
    else
      url "https://releases.antfly.io/antfly/v0.2.1/antfly_0.2.1_Linux_x86_64_gnu.tar.gz"
      sha256 "2378190c86966626e5a6a101918f66f0f175c8f7482a85415fc446a2a09427d7"
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
    (testpath/"smoke.c").write <<~C
      #include <antfly.h>
      int main(void) {
        if (antfly_abi_version() != 1) return 1;
        void *db = NULL;
        if (antfly_lite_create("smoke.aflite", &db) != ANTFLY_OK) return 2;
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
