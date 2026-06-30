# AntflyDB Homebrew Taps

This is the official source for installing AntflyDB tools with Homebrew.

## Installing

```bash
# Install Antfly
$ brew install antflydb/taps/antfly
```

Alternatively, you can configure the tap and install the packages separately:

```bash
$ brew tap antflydb/taps
$ brew trust --formula antflydb/taps/antfly
$ brew install antfly
```

Homebrew's Tap Trust model requires explicit trust for non-official taps before
Homebrew loads their formulae, casks, or external commands. Fully-qualified
installs, such as `brew install antflydb/taps/antfly`, trust only that package.
If you want to install by short name from the tapped repository, trust the
specific formula or cask first:

```bash
$ brew trust --formula antflydb/taps/antfly
$ brew trust --cask antflydb/taps/antflycli
```

For a Brewfile, prefer item-level trust:

```ruby
tap "antflydb/taps", trusted: {
  formula: "antfly",
  cask: "antflycli",
}

brew "antfly"
cask "antflycli"
```

If you administer the machine and want Homebrew to load every current and future
package from this tap, you can trust the whole tap instead:

```bash
$ brew tap antflydb/taps
$ brew trust antflydb/taps
```

Run Antfly as a local service:

```bash
$ brew services start antfly
```

## Documentation

For more information about AntflyDB, visit [https://docs.antfly.io](https://docs.antfly.io)

## License

Apache License 2.0
