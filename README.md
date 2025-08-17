# Weinstein, Frankenstein Wine builds

Ever wanted to test a patch but not install all Wine dependencies, or compile every DLL?
This repository addresses both at once by reusing existing Wine installations - preferably
one of a recent Wine development version.

Warning: You might need tinkering depending on the complexity of the DLL you'd like to patch.

## Installation

 * `unionfs-fuse`: To create a new fake Wine installation by overlaying two directories.
 * [Get a compiled Wine version](https://gitlab.winehq.org/wine/wine/-/wikis/Download) (if not already done)
 * You need at least `winegcc`/`wineg++` to compile static ELF binaries and generate stub DLLs.
   On Debian-based systems, these are provided in the `wine-devel`.
 * [Clone the Wine source repository](https://gitlab.winehq.org/wine/wine/-/wikis/Git-Wine-Tutorial)
 * [Packages needed for your patched DLLs](https://gitlab.winehq.org/wine/wine/-/wikis/Building-Wine#satisfying-build-dependencies)
    * Note: The MinGW cross-compiler is not required. The aforementioned stub DLLs do generally suffice.

### Source compiling setup

This repository generally assumes that 64-bit DLLs shall be built. i386 is yet untested.

```sh
cd 'my/wine/git/clone'
./configure --enable-win64
```

If a `wine*` tool cannot be found by `configure`, you might need to specify the paths manually
(`./configure CC='/path/to/gcc'`, or add symlinks to `/bin`


### config.sh

Please copy `config.template.sh` to `config.sh` and adjust the paths as needed.


## Usage notes

### Useful script examples

```sh
# Build shell32, add it to the fake install, and run cmd.exe
bash weinstein.sh --build shell32 --apply shell32 --run cmd.exe

# Same thing, but shorter
bash weinstein.sh b shell32 a shell32 r cmd.exe

# Use a custom WINEPREFIX for testing
WINEPREFIX="/my/testing/prefix" bash weinstein.sh r cmd.exe
```


### Switching to another Wine version

After a Wine package upgrade, you should update your Wine clone as well to stay compatible.
Keep in mind that the overridden DLLs should either be removed or recompiled.

When using shallow git clones, you might not want to retrieve the entire history of the
repository. The commands below do respect that.

```sh
# This also retrieves all tags between your current repository checkout
# and the specified version tag.
git fetch origin refs/tags/wine-[MM.NN]:refs/tags/wine-[MM.NN]

# Switch to the tag (detached)
git checkout wine-[MM.NN]
```
