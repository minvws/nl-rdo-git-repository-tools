# RDO Git Repository Tools
## Usage

```
repotools sync-repo \
    --public-github-path organisation/repo-public \     # github path
    --private-github-path organisation/repo-private \   # github path
    --matching-tags-pattern "Holder-" \                 # Tags matching this tag .. 
    --matching-tags-pattern "Verifier-" \               # .. or this tag, will be pushed.
    --excluding-tag-pattern \\-RC \                     # don't push "-RC" (Release Candidate) tags
    ~/path/to/your-repo-private
```

## Installation: 

The project uses the [Mint](https://github.com/yonaskolb/Mint) package manager: 

`brew install mint` 

After that, you can install this tool using:

`mint install minvws/nl-rdo-git-repository-tools`

(you may wish to add `.mint/bin` to your $PATH)