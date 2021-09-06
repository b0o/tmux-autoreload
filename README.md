# tmux-autoreload [![version](https://img.shields.io/github/v/tag/b0o/tmux-autoreload?style=flat&color=yellow&label=version&sort=semver)](https://github.com/b0o/tmux-autoreload/releases) [![license: MIT](https://img.shields.io/github/license/b0o/tmux-autoreload?style=flat&color=green)](https://mit-license.org)

tmux-autoreload watches your tmux configuration file and automatically reloads
it on change.

## Install

### Dependencies

- [entr](https://github.com/eradman/entr)

### TPM (Tmux Plugin Manager)

To install with [TPM](https://github.com/tmux-plugins/tpm), add the following line to your `tmux.conf`:

```sh
set-option -g @plugin 'b0o/tmux-autoreload'
```

Then, restart tmux or manually source your config file. Finally, press your TPM install keybinding (defaults to `prefix + I`) to install and start the plugin.

### Manual Install

Clone the repo to your desired location:

```sh
git clone https://github.com/b0o/tmux-autoreload /path/to/tmux-autoreload
```

Then, add the following line to your `tmux.conf`:

```sh
run-shell "/path/to/tmux-autoreload/tmux-autoreload.tmux"
```

## Usage

Once you've installed tmux-autoreload, that's it! When you edit and write your
`tmux.conf`, tmux-autoreload will tell tmux to source it.

### Advanced Usage

<!-- USAGE -->

```

Usage: tmux-autoreload.tmux [-f] [OPT...]

Watches your tmux configuration file and automatically reloads it on change.

Options
  -h      Display usage information.
  -v      Display tmux-autoreload version and copyright information.
  -f      Run in foreground (do not fork).
  -k      Kill the running instance of tmux-autoreload.
  -s      Show status of tmux-autoreload.
  -m MSG  Display MSG on all clients.
  -M MSG  Display MSG on all clients (wait for keypress).

```

<!-- /USAGE -->

## License

<!-- LICENSE -->

&copy; 2021 Maddison Hellstrom

Released under the MIT License.

<!-- /LICENSE -->
