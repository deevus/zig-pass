# Zig Pass

Zig Pass is a terminal client for [Password Store](https://www.passwordstore.org/) that is compatible with MacOS, Linux and Windows (without requiring the use of WSL).

Zig Pass aims to be somewhat compatible with the bash client, so that you can use it in place of `pass` without much trouble. If you have dotfiles that depend on `pass`, you may be able to start using them on Windows too, by simply aliasing `zig-pass` to `pass`.

# Requirements

- GPGME

# Why

I've been using Password Store for many years. The [Password Store Bash Client](https://git.zx2c4.com/password-store) works great on MacOS and Linux. However it doesn't work properly on Windows, due to a lack of an easily attainable `getopt` binary. You can use [Pass Winmenu](https://github.com/geluk/pass-winmenu) (and I do), but it doesn't expose a terminal client.

My particular use-case is using a dotfile manager: [Chezmoi](https://www.chezmoi.io/). Using Chezmoi and `pass`, I can apply dotfile templates for shells such as zsh and bash, or my Neovim config. I have tokens for GitHub and other software tools in my Password Store that I use in Neovim config for example.

# Feature Matrix

| Feature            | Windows | Linux | MacOS |
| ------------------ | ------- | ----- | ----- |
| Show password file | ✅      | ✅    | ✅   |
| Copy to clipboard  | ✅      | ✅    | ✅   |
| QRCode             | ❌      | ❌    | ❌    |
| Create password    | ❌      | ❌    | ❌    |
| Edit password      | ❌      | ❌    | ❌    |
| Git Operations     | ✅      | ✅    | ✅    |

`SPDX-License-Identifier: LGPL-2.1 and GPL-2.0 and MIT`
