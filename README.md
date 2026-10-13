# container-backup

A container that keeps a versioned copy of another container's folders, out of
that container's reach.

The copy is evidence, not an export: what was copied once can no longer be
changed, and any later rewrite shows. The watched container can still write
anything in its folders now; it cannot change what was already recorded.

Built first for [agent](https://github.com/Adsdworld/agent), usable for any
container whose folders it can mount.

## Contract

- It mounts the folders to copy read-only under `/source/<name>`, and its own
  `/backup/data` read-write. The watched container never mounts `/backup/data`.
- It pulls: it receives nothing from the watched container.
- It has no network (`network_mode: none`).
- The watched container's data is hostile input: it never runs anything that
  comes from it. It copies bytes, and only runs git in its own repository.

## Run

```yaml
services:
  backup:
    image: ghcr.io/adsdworld/container-backup:latest
    network_mode: none
    cap_drop: [ALL]
    cap_add: [DAC_READ_SEARCH]   # read files of any owner, write nothing else
    volumes:
      - ./backup/config:/backup/config:ro
      - ./backup/data:/backup/data
      - ./agent:/source/agent:ro
      - ./firewall/config:/source/firewall-config:ro
```

Every folder mounted under `/source/<name>` is copied. Mount them read-only:
the backup never writes to them, and the mount makes sure of it.

| Variable | Default | Description |
|---|---|---|
| `BACKUP_INTERVAL` | `300` | Seconds between the starts of two copies. |
| `BACKUP_EXCLUDE` | none | rsync patterns left out of the copy, separated by spaces, for example `venv/ /logs/runs/`. |

Variables can also live in `/backup/config/environment`, one `NAME=value` per
line.

## What it keeps

```
/backup/data/
├── files/          git repository: the files of the sources, without their .git folders
├── repositories/   one bare mirror per git repository found in the sources
├── staging/        the raw copy of the sources, kept to make the next copy faster
└── ALERTS          what was found changed in a history already recorded
```

```bash
git -C backup/data/files log --stat              # what changed, copy after copy
git -C backup/data/files show HEAD~3:agent/data/CLAUDE.md
git -C backup/data/repositories/agent/data/scripts.git for-each-ref
cat backup/data/ALERTS
```

## How it copies

Every `BACKUP_INTERVAL` seconds, counted from the start of the previous copy:

1. Each `/source/<name>` is copied into `staging/` with rsync. Symbolic links
   are copied as links, never followed; devices and special files are left out.
2. Each `.git` folder found in `staging/` is recorded in its mirror in
   `repositories/`. Every ref of the source is kept under `refs/source/`, and
   nothing is ever pruned:
   - a ref that moved without descending from where it was is a **rewrite**:
     the previous history is kept as `refs/rewritten/<time>/<ref>`;
   - a ref that disappeared is kept as `refs/deleted/<time>/<ref>`;
   - a repository that disappeared keeps its mirror.

   Each of these is written to `ALERTS` and to the container's output.
3. The files, without the `.git` folders, are committed in `files/`.

It does not wait for the watched container to be idle: that container could
then block the backups forever.

A file changed and changed back between two copies leaves no trace: the
shorter `BACKUP_INTERVAL`, the smaller this window.

## The sources are hostile

Nothing that comes from them is ever run or trusted:

- git never runs inside the sources. In its copy of each repository, the
  configuration is replaced and the hooks, alternates and grafts are removed
  before git reads it, so a `.git/config` cannot make git run a command.
- In `files/`, the copied `.gitignore` and `.gitattributes` are not honoured:
  nothing can be hidden from the copy or converted on the way in.
- Git runs with no system or global configuration, no hooks and no fsmonitor.

## Open questions

- Who is told when a rewrite is detected, given that the container has no
  network (#2).

## License

Apache-2.0
