# container-backup

A container that keeps a versioned copy of another container's folders, out of
that container's reach.

The copy is for traceability: what was copied once can no longer be changed.
The watched container can still write anything in its folders now; it cannot
change what was already recorded.

Built first for [agent](https://github.com/Adsdworld/agent), usable for any
container whose folders it can mount.

## Contract

- It mounts the folders to copy read-only under `/source`, and `/data`
  read-write. The watched container never mounts `/data`.
- It pulls: it receives nothing from the watched container.
- It has no network.
- What it copies is data, never instructions: nothing from `/source` is run,
  and the `.gitignore` and `.gitattributes` found there are not honoured, so
  nothing can be hidden from the copy or changed on the way in.

## Run

```yaml
services:
  backup:
    image: ghcr.io/adsdworld/container-backup:latest
    network_mode: none
    cap_drop: [ALL]
    cap_add: [DAC_READ_SEARCH]
    volumes:
      - ./backup/config:/config:ro
      - ./backup/data:/data
      - ./agent:/source/agent:ro
      - ./firewall/config:/source/firewall:ro
```

`/config/config`, required:

```
interval 300
```

`interval` is the number of seconds between the starts of two copies.
[`examples/config`](examples/config) is a complete file.

## What it does

Every `interval` seconds:

1. It copies the content of `/source` into `/data`, without the `.git` folders
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
shorter `interval`, the smaller this window.

## License

Apache-2.0
