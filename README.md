# RDO Git Repository Tools

There is currently one tool implemented: `sync-repo`.

## Sync Repo

`sync-repo` is a tool for automating the syncing of a "private" git origin with a "public" git origin, together with a set of tags that exists only at the private repo, so that a merge PR can be quickly opened.

### Usage

```
repotools sync-repo \
    --public-github-path organisation/repo-public \     # github path
    --private-github-path organisation/repo-private \   # github path
    --matching-tags-pattern "Holder-" \                 # Tags matching this tag .. 
    --matching-tags-pattern "Verifier-" \               # .. or this tag, will be pushed.
    --excluding-tag-pattern \\-RC \                     # don't push "-RC" (Release Candidate) tags
    ~/path/to/your-repo-private
```

## Requirements for installation using Mint

* macOS 13.0.0 or higher, or [Linux](https://github.com/yonaskolb/Mint#linux)

## Installation: 

The project uses the [Mint](https://github.com/yonaskolb/Mint) package manager: 

`brew install mint` 

After that, you can install this tool globally using:

`mint install minvws/nl-rdo-git-repository-tools@main`

or 

`mint install git@github.com:minvws/nl-rdo-git-repository-tools.git@main`

(you may wish to add `.mint/bin` to your $PATH).
