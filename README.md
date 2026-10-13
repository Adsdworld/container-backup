# container-backup

A container that keeps a versioned copy of another container's folders, out of
that container's reach.

The copy is evidence, not an export: what was copied once can no longer be
changed, and any later rewrite shows. The watched container can still write
anything in its folders now; it cannot change what was already recorded.

Built first for [agent](https://github.com/Adsdworld/agent), usable for any
container whose folders it can mount.

## Contract

- It mounts the folders to copy read-only, and its own `/backup/data`
  read-write. The watched container never mounts `/backup/data`.
- It pulls: it receives nothing from the watched container.
- It has no network (`network_mode: none`).
- The watched container's data is hostile input: it never runs anything that
  comes from it. It copies bytes, and only runs git in its own repository.

## Folders

```
/backup/config/   (ro)   BACKUP_INTERVAL…
/backup/data/     (rw)   the versioned copy
/source/<name>/   (ro)   each folder to copy
```

## How it copies

Every `BACKUP_INTERVAL` seconds:

1. It copies each `/source/<name>` into a staging folder, without following
   symbolic links.
2. It commits the staging folder in its own git repository, in `/backup/data`.
3. It keeps the history of the git repositories it finds in the sources next to
   it, never pruned: a history rewritten since the last copy shows as a branch
   that moved without descending from the previous one.

It does not wait for the watched container to be idle: that container could
then block the backups forever. A copy taken while it was working says so.

A file changed and changed back between two copies leaves no trace: the
shorter `BACKUP_INTERVAL`, the smaller this window.

## Open questions

- How the history of the sources' git repositories is kept: git cannot version
  a `.git` folder inside another repository (mirrors, bundles).
- Who is told when a rewrite is detected, given that the container has no
  network.

## License

Apache-2.0
