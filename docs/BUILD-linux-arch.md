# Building Savage Wind on Arch-based Linux (x86-64)

Notes for building from source on Arch / CachyOS (and other Arch derivatives), where the
distribution's package names and layouts differ from the Ubuntu / Debian instructions in
[docs/linux.md](linux.md). Verified building and running the start screen on CachyOS
(clang 23, SDL3 3.4, FFmpeg 9, shaderc 2026.4, RADV on an AMD GPU).

## Packages

    sudo pacman -S clang lld make pkgconf python sdl3 ffmpeg vulkan-headers \
        vulkan-icd-loader shaderc vulkan-tools

The distribution does not package Vulkan Memory Allocator (`vk_mem_alloc.h`), which the
Vulkan renderer needs (`runtime/nvn/vulkan/vk.h`, `vma.cpp`). Fetch the header and put it
somewhere clang finds it, for example:

    mkdir -p ~/tools-prefix/include
    curl -L -o ~/tools-prefix/include/vk_mem_alloc.h \
        https://raw.githubusercontent.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/master/include/vk_mem_alloc.h

Arch's shaderc installs `libshaderc_shared.so.1` / `libshaderc.a` but no `libshaderc.so`.
The Makefile links `-lshaderc` by default, so point it at a linkable name (or override
`SHADERC`):

    ln -sf /usr/lib/libshaderc_shared.so.1 ~/tools-prefix/lib/libshaderc.so

## Build

    python3 -m venv tools/venv && tools/venv/bin/pip install lz4 capstone unicorn
    make -j DEPS=$HOME/tools-prefix      # the start screen -> build/savagewind
    # after setting up your own game files (or putting extracted/ here):
    make gen                             # once: recompile the game from your own game files
    make -j DEPS=$HOME/tools-prefix      # -> build/swgame.so next to build/savagewind

`DEPS=<prefix>` points the includes, libraries and rpath at that prefix; the same variable
also feeds `make gen` and the rebuild of the game code from the start screen, so keep using
it for every `make` invocation.

Run from the repo root (`extracted/` in the starting folder selects dev mode) or via the
AppImage. `make appimage` builds the release AppImage in a podman container and does not
need any of the above: only `podman`.

## AppImage: Arch or Ubuntu, and the glibc floor

Two build images, both driven by `tools/linux/appimage.sh`:

| Command | Image | Needs at run time |
|---|---|---|
| `make appimage` | Ubuntu 22.04 (`tools/linux/Containerfile`) | glibc 2.35+ |
| `make appimage-arch` / `make appimage BASE=arch` | Arch (`tools/linux/Containerfile.arch`) | a recent distribution |

The Arch image is what `.github/workflows/release-linux.yml` builds, and it is the simpler
one to get working: no PPA, no `python3.12`, just `pacman -Syu`. The trade-off is the glibc
floor: the AppImage links against Arch's glibc, which is far newer than 2.35. Measured on a
CachyOS build (glibc 2.44): the packaged `savagewind` requires **GLIBC_2.43**, so that
AppImage runs on Arch/CachyOS/Fedora rawhide and future distributions, not on Ubuntu 24.04
or Debian 13. Use `make appimage` (Ubuntu image) for an AppImage that must run on older
distributions. Both build the same AppDir from `tools/linux/package.sh`.

## Notes

- The `tools/linux/*.sh` scripts are executable in git (mode 100755). They were committed as
  100644, which `make appimage` never noticed (podman runs them as an argument) but a CI job
  calling them directly does: `Permission denied`. `tools/fetch_zig.sh` had the same problem.
- The header's `-Wnullability-completeness` warnings are noise from VMA under clang and do
  not affect the build.
- No `sudo` is needed for the prefix; keep it outside the repo so it stays untracked.