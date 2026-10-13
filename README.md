# container-backup

A container that keeps a versioned copy of another container's folders, out of
that container's reach.

The copy is for traceability: what was copied once can no longer be changed.
The watched container can still write anything in its folders now; it cannot
change what was already recorded.

Built first for [agent](https://github.com/Adsdworld/agent), usable for any
container whose folders it can mount.

## Contract

- It mounts the folder to copy read-only at `SOURCE_FOLDER`, and `/data`
  read-write. The watched container never mounts `/data`.
- It pulls: it receives nothing from the watched container.
- It has no network.
- What it copies is data, never instructions: nothing from `SOURCE_FOLDER` is
  run, and the `.gitignore` and `.gitattributes` found there are not honoured,
  so nothing can be hidden from the copy or changed on the way in.

## Run

```yaml
services:
  backup:
    image: ghcr.io/adsdworld/container-backup:latest
    network_mode: none
    cap_drop: [ALL]
    cap_add: [DAC_READ_SEARCH]
    environment:
      BACKUP_INTERVAL: "300"
    volumes:
      - ./backup/data:/data
      - ./agent:/source/agent:ro
      - ./firewall/config:/source/firewall:ro
```

| Variable | Default | Description |
|---|---|---|
| `BACKUP_INTERVAL` | `300` | Seconds between the starts of two copies. |
| `SOURCE_FOLDER` | `/source` | The folder whose content is copied. |

An invalid `BACKUP_INTERVAL` stops the container.

## Health check

`backup-health` prints `Ok` when `SOURCE_FOLDER` can be read and `/data` can
be written, and the reason otherwise. The image declares it: ready at the
first `Ok`, not ready at the first failure.

```dockerfile
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --start-interval=1s --retries=1 \
    CMD backup-health | grep -qx Ok
```

It is a command, not an HTTP endpoint: the container has no network.

## What it does

Every `BACKUP_INTERVAL` seconds:

1. It copies the content of `SOURCE_FOLDER` into `/data`, without the `.git` folders
   it finds there. Symbolic links are copied as links, never followed.
2. It commits `/data` when something changed, with the date and time as the
   message.

```
/source/                /data/
├── file1               ├── .git/
└── dossier1/           ├── file1
    └── repo/.git/      └── dossier1/
                            └── repo/
```

```bash
git -C backup/data log --stat
git -C backup/data show 'HEAD@{yesterday}:agent/data/CLAUDE.md'
```

A file changed and changed back between two copies leaves no trace: the
shorter `BACKUP_INTERVAL`, the smaller this window.

## License

Apache-2.0
