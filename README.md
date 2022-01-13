# tmux-autoreload [![version](https://img.shields.io/github/v/tag/b0o/tmux-autoreload?style=flat&color=yellow&label=version&sort=semver)](https://github.com/b0o/tmux-autoreload/releases) [![license: MIT](https://img.shields.io/github/license/b0o/tmux-autoreload?style=flat&color=green)](https://mit-license.org)

tmux-autoreload watches your tmux configuration file and automatically reloads
it on change.

## Install

#### Dependencies

- [entr](https://github.com/eradman/entr)

## Installation

To install tmux-autoreload with TPM (https://github.com/tmux-plugins/tpm), add the
following line to the end of your tmux configuration file:

```sh
set-option -g @plugin 'b0o/tmux-autoreload'
```

Then, inside tmux, press `prefix + I` to fetch the plugin.

If you don't use a plugin manager, git clone tmux-autoreload to the location of your
choice and run it directly:

```sh
run-shell "/path/to/tmux-autoreload/tmux-autoreload.tmux"
```

## Setup

Once installed, you should be good to go unless you use non-standard
configuration file paths or want to customize how tmux-autoreload behaves.

### Configuration file paths

If your tmux config file is at a non-standard location or if you have multiple,
specify them in `@tmux-autoreload-configs`, separated by commas:

```sh
set-option -g @tmux-autoreload-configs '/path/to/configs/a.conf,/path/to/configs/b.conf'
```

### Entrypoints

Normally, tmux-autoreload will source whichever file changed. If you wish to
source a specific set of files when any configuration file changes, use
`@tmux-autoreload-entrypoints`:

```sh
set-option -g @tmux-autoreload-entrypoints '/path/to/entrypoint.conf'
```

You can specify multiple entrypoints separated by commas. All entrypoints
will be sourced when any watched file changes.

Set `@tmux-autoreload-entrypoints` to 1 to use the standard tmux configuration
files as entrypoints, usually `/etc/tmux.conf` and `~/.tmux.conf.` You can see
these files with:

```sh
tmux display-message -p "#{config_files}"
```

#### Entrypoint Notes

- If entrypoints are configured, a changed file itself will not necessarily
  be reloaded unless it's an entrypoint or is sourced by an entrypoint.

- Entrypoints will not be watched unless they're a standard tmux
  configuration file like `~/.tmux.conf` or are included in `@tmux-autoreload-configs.`

### All Options

```
@tmux-autoreload-configs (Default: unset)
  A comma-delimited list of paths to configuration files which should be
  watched in addition to the base tmux configuration files.

@tmux-autoreload-entrypoints (Default: unset)
  A comma-delimited list of paths to configuration files which should be
  reloaded when any watched configuration file changes. If unset, the changed
  file itself will be reloaded.

  If set, only the entrypoints will be reloaded, not necessarily the changed
  file.

  If set to 1, the base tmux configuration files are used as the entrypoints
  (you can see the base configuration files with the command tmux
  display-message -p "#{config_files}").

@tmux-autoreload-quiet 0|1 (Default: 0)
  If set to 1, tmux-autoreload will not display status messages.
```

## Advanced Usage

<!-- USAGE -->

```

Usage: tmux-autoreload.tmux [-f] [OPT...]
  Automatically reloads your tmux configuration files on change.

Options
  -h      Display usage information.
  -v      Display tmux-autoreload version and copyright information.
  -f      Run in foreground (do not fork).
  -k      Kill the running tmux-autoreload instance.
  -s      Show tmux-autoreload status

Installation
  To install tmux-autoreload with TPM (https://github.com/tmux-plugins/tpm), add the
  following line to the end of your tmux configuration file:
      set-option -g @plugin 'b0o/tmux-autoreload'

  If you don't use a plugin manager, git clone tmux-autoreload to the location of your
  choice and run it directly:
      run-shell "/path/to/tmux-autoreload/tmux-autoreload.tmux"

  Once installed, you should be good to go unless you use non-standard
  configuration file paths or want to customize how tmux-autoreload behaves.

Configuration file paths
  If your config file is at a non-standard location or if you have multiple,
  specify them in @tmux-autoreload-configs, separated by commas:
    set-option -g @tmux-autoreload-configs '/path/to/configs/a.conf,/path/to/configs/b.conf'

Entrypoints
  Normally, tmux-autoreload will source whichever file changed. If you wish to
  source a specific set of files when any configuration file changes, use
  @tmux-autoreload-entrypoints:
    set-option -g @tmux-autoreload-entrypoints '/path/to/entrypoint.conf'

  You can specify multiple entrypoints separated by commas. All entrypoints
  will be sourced when any watched file changes.

  Set @tmux-autoreload-entrypoints to 1 to use the standard tmux configuration
  files as entrypoints, usually /etc/tmux.conf and ~/.tmux.conf. You can see
  these files with:
    tmux display-message -p "#{config_files}".

  Entrypoint Notes:
  - If entrypoints are configured, a changed file itself will not necessarily
    be reloaded unless it's an entrypoint or is sourced by an entrypoint.

  - Entrypoints will not be watched unless they're a standard tmux
    configuration file like ~/.tmux.conf or are included in @tmux-autoreload-configs.

Other Options
  @tmux-autoreload-quiet 0|1 (Default: 0)
    If set to 1, tmux-autoreload will not display messages

```

<!-- /USAGE -->

## License

<!-- LICENSE -->

&copy; 2021 Maddison Hellstrom

Released under the MIT License.

<!-- /LICENSE -->
