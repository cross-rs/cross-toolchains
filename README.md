# `cross-toolchains`

Additional Dockerfiles and crosstool-ng config files to build images for additional targets. These enable the use of additional targets, and different glibc or GCC versions.

First, clone [cross](https://github.com/cross-rs/cross) and update the submodules.

```bash
git clone https://github.com/cross-rs/cross
cd cross
git submodule update --init
```

Then, you can build your images as shown in [Targets](#targets).

> ℹ️ These images are not tested with CI, and therefore may break. Issues or pull requests to fix broken images are greatly appreciated. Each image is only confirmed to at least build once.

## Configure

The config files are configured via [crosstool-ng/configure-all.sh](/crosstool-ng/configure-all.sh), which may be customized by the following environment variables:

- `GCC_VERSION`: The GCC version (default `8.3.0`)
- `GLIBC_VERSION`: The glibc version (default `2.17`)
- `LINUX_VERSION`: The Linux version (default `4.19.21`)

## Targets

The image names don't map identically to the target names, to avoid conflicting with those provided in the [cross](https://github.com/cross-rs/cross) repository. This table maps the target names to the image names:

| Target Name                           | Image Name                                  |
|:-------------------------------------:|:-------------------------------------------:|
| aarch64-pc-windows-msvc               | aarch64-pc-windows-msvc-cross               |
| aarch64_be-unknown-linux-gnu          | aarch64_be-unknown-linux-gnu-cross          |
| i686-apple-darwin                     | i686-apple-darwin-cross                     |
| i686-pc-windows-msvc                  | i686-pc-windows-msvc-cross                  |
| s390x-unknown-linux-gnu               | s390x-unknown-linux-gnu-cross               |
| thumbv7a-pc-windows-msvc              | thumbv7a-pc-windows-msvc-cross              |
| thumbv7neon-unknown-linux-musleabihf  | thumbv7neon-unknown-linux-musleabihf-cross  |
| x86_64-apple-darwin                   | x86_64-apple-darwin-cross                   |
| x86_64-pc-windows-msvc                | x86_64-pc-windows-msvc-cross                |

For example, to build and run an image, you would configure the image with:

```bash
cargo build-docker-image s390x-unknown-linux-gnu-cross --tag local
```

And then update `Cross.toml` in your crate to specify the target:

```toml
[target.s390x-unknown-linux-gnu]
image = "ghcr.io/cross-rs/s390x-unknown-linux-gnu-cross:local"
```

Additional config files for any [supported platforms](https://doc.rust-lang.org/rustc/platform-support.html) are appreciated. Please note that many of these images are tier 3 targets, and do not have pre-built versions of the standard library. You must provide the `build-std` [config](https://github.com/cross-rs/cross/wiki/Configuration) option when building crates requiring `std` support.

# Apple Targets

Due to licensing [reasons](https://www.apple.com/legal/sla/docs/xcode.pdf), we cannot provide images of `*-apple-darwin` targets, nor host the macOS SDK. osxcross has instructions for how to package the [sdk](https://github.com/tpoechtrager/osxcross#packaging-the-sdk), which you can then provide to the Docker image as either a local file or download link. Pre-packaged tarballs can also be found online, however, for legal reasons, we do not provide links here.

You can provide either a download URL or a path to a local file when building:

```bash
$ cargo build-docker-image i686-apple-darwin \
  --build-arg 'MACOS_SDK_URL=$URL'
$ cargo build-docker-image i686-apple-darwin \
  --build-arg 'MACOS_SDK_DIR=$DIR' \
  --build-arg 'MACOS_SDK_FILE=$FILE'
```

If not provided, `MACOS_SDK_DIR` defaults to the build context of the Dockerfile. Note that this file must be a subdirectory of the build context.

## Known Issues

- Older toolchains, such as GCC v4.9.4, do not work with the hardcoded ISL v0.20.
- s390x toolchains cannot be built with glibc below v2.20, due to missing symbols in `nptl/sysdeps/s390/tls.h`.
- aarch64_be toolchains cannot be built with older glibc versions, due relocations (tested to work in v2.31, failed in v2.20).
- MSVC targets may fail with more complex build systems, such as OpenSSL.

## Code of Conduct

Contribution to this crate is organized under the terms of the [Rust Code of
Conduct][CoC], the maintainer of this crate, the [cross-rs] team, promises
to intervene to uphold that code of conduct.

[CoC]: CODE_OF_CONDUCT.md
[cross-rs]: https://github.com/cross-rs
[Matrix room]: https://matrix.to/#/#cross-rs:matrix.org
