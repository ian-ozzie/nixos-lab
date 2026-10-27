# Forgejo

By default runs under `git`, and configures `openssh` to allow access.

## backup

Nightly database dump (if `ozzie.lab.mysql.backup.enable = true`), and files within
`/data/services/forgejo`

## migration

### backup

```bash
# Create dump archive, from /data/services/forgejo
nix run nixpkgs#forgejo -- dump --type tar.gz --database mysql --config custom/conf/app.ini

# Transfer backup to new host
scp /data/services/forgejo/forgejo-dump-*.tar.gz new-server:
```

### restore

```bash
# Transfer to server, extract on /data/services/forgejo
tar -zxf forgejo-dump-*.tar.gz

# Restore db, disable foreign keys so import doesn't choke on foreign keys:
# ERROR 1005 (HY000) at line 31: Can't create table `forgejo`.`access_token_resource_repo` (errno: 150 "Foreign key constraint is incorrectly formed")
mariadb --init-command='SET SESSION FOREIGN_KEY_CHECKS=0' forgejo < forgejo-db.sql

# Migrate db
nix run nixpkgs#forgejo -- migrate -c custom/conf/app.ini

# Clean up
rm forgejo-dump-*.tar.gz forgejo-db.sql
```
