# Atuin

## Client

`.bashrc`, needs
`curl -fsSL https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o ~/.bash-preexec.sh`

```bashrc
source ~/.bash-preexec.sh
eval "$(atuin init bash --disable-ai --disable-up-arrow)"
```

`.config/atuin/config.toml`

```toml
dialect = "uk"
auto_sync = true
enter_accept = true
exit_mode = "return-original"
filter_mode = "host"
inline_height = 20
search_mode = "fulltext"
show_help = false
show_preview = true
show_tabs = false
style = "compact"
update_check = false

[daemon]
enabled = true
autostart = false
```

Commands

```bash
# Enable ozzie.lab.atuin-daemon socket
systemctl --user start atuin-daemon.socket

# Register/login
atuin register -u <user> -e <email>
atuin login

# Sync
atuin sync

# Import
atuin import auto
```
