# nada_album
Takes a collection of wav files and converts them to mp3 and sets meta data. It will also work on mp3 files if you just want to set all the meta data for them properly. It behaves the same way by copying the files to a new directory, so the original files remain intact.

### requirements
*nix type system (osx/linux/etc) with `lame` installed

in OSX
```bash
brew install lame
```

### usage

```bash
./nada_album.sh "<folder to convert>"
```