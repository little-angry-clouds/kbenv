# kbenv
[Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) version
manager inspired by [tfenv](https://github.com/tfutils/tfenv/).

## Support
Currently kbenv supports the following OSes
- Mac OS X (64bit) - not really tested
- Linux
  - 32bit
  - 64bit
  - Arm
  - Arm64

## Installation
1. Check out kbenv into any path (`${HOME}/.kbenv` in the example)

```bash
git clone https://github.com/alexppg/kbenv.git ~/.kbenv
```

2. Add `~/.bin` to your `$PATH`

```bash
echo 'export PATH="$HOME/.bin:$PATH"' >> ~/.bashrc
# Or
echo 'export PATH="$HOME/.bin:$PATH"' >> ~/.zshrc
```

3. Source the script
```bash
echo 'source $HOME/.kbenv/kbenv.sh' >> ~/.bashrc
# Or
echo 'source $HOME/.kbenv/kbenv.sh' >> ~/.zshrc
```

## Usage
### kbenv help

``` bash
$ kbenv help
Usage: kbenv <command> [<options>]
Commands:
    list-remote   List all installable versions
    list          List all installed versions
    install       Install a specific version
    use           Switch to specific version
    uninstall     Uninstall a specific version
```

### kbenv list-remote
List installable versions:

```bash
$ kbenv list-remote
Fetching versions...
v1.10.9
v1.10.10
v1.10.11
v1.10.12
v1.11.0
v1.11.1
v1.11.2
...
```

### kbenv list
List installed versions:
```bash
$ kbenv list
v1.9.11
v1.10.9
```

### kbenv install
Install a specific version:

```bash
$ kbenv install v1.8.14
Downloading binary...
kubectl is pointing to the v1.9.11 version
Do you want to overwrite it? (y/n)
y
Done! Now kubectl points to the v1.8.14 version
```

### kbenv use
Switch to specific version:

```bash
$ kbenv use v1.9.11
Done! Now kubectl points to the v1.9.11 version
```

### kbenv uninstall
Uninstall a specific version:
```bash
$ kbenv uninstall v1.9.11
The version v1.9.11 is uninstalled!
```

## Related Projects
There's a similar project for managing [helm
versions](https://github.com/alexppg/helmenv).

## License
GPL3
