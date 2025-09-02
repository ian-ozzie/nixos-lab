# services

## forgejo

### migration steps

```
# Create dump archive, from /data/services/forgejo
forgejo dump --database mysql --config custom/conf/app.ini

# Transfer to server, extract on /data/services/forgejo
unzip forgejo-dump-*.zip

# Restore db
mysql forgejo < forgejo-db.sql && rm forgejo-db.sql
```
