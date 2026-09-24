# typed: false
# frozen_string_literal: true

class Antfly < Formula
  desc "Native Zig AntflyDB runtime"
  homepage "https://docs.antfly.io"
  version "0.2.3"
  # Recover from older formulae that inferred version 64 from arm64 archives.
  version_scheme 1
  license "Elastic-2.0"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://releases.antfly.io/antfly/v0.2.3/antfly_0.2.3_Darwin_arm64.tar.gz"
      sha256 "487acfb5a5854ef41fe022eba9808cf2de9988096404714e812190831a956ce5"
    else
      odie "antfly supports Apple Silicon macOS only"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://releases.antfly.io/antfly/v0.2.3/antfly_0.2.3_Linux_arm64_gnu.tar.gz"
      sha256 "460568949564200cb754787f4f61ca1daa998d8c1e329cafff4e11c08128348e"
    else
      url "https://releases.antfly.io/antfly/v0.2.3/antfly_0.2.3_Linux_x86_64_gnu.tar.gz"
      sha256 "410bfce796eb814370a6b546f29d0d847b2ee834d224cf28a1ecd1ed7823e82b"
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
