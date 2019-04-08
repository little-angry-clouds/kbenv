#!/usr/bin/env bash

function _kbenv_test_requirements {
    if [[ ! "$(command -v curl)" ]]
    then
        echo "You must install curl"
        exit 1
    elif [[ ! "$(command -v jq)" ]]
    then
         echo "You must install jq"
         exit 1
    fi
}

function _kbenv_get_so_and_arch(){
    local _uname
    local _arch

    _uname="$(uname -s)"
    _arch="$(arch)"

    case "${_uname}" in
        Linux)  machine=linux;;
        Darwin) machine=darwin;;
        *)      machine="UNKNOWN:${_uname}"
    esac

    case "${_arch}" in
        arm)    architecture="arm";;
        arm64)  architecture="arm64";;
        x86_64) architecture="amd64";;
        *)      architecture="UNKNOWN:${_arch}"
    esac

    if [[ "$machine" == "darwin" ]]
    then
        echo "$machine/amd64"
        return 0
    fi

    echo "$machine/$architecture"
}

function kbenv_list_remote () {
    echo "Fetching versions..."
    # TODO Paginate over this url
    versions_url="https://api.github.com/repos/kubernetes/kubernetes/releases?per_page=100"
    versions="$(curl -s "$versions_url" | jq -r ".[].tag_name" | grep -v "rc\\|beta\\|alpha" | sort --version-sort)"
    echo "$versions"
    return 0
}

function kbenv_install () {
    VERSION="$1"

    if [[ -z "$VERSION" ]] && [[ -t 1 && -z ${KBENV_IGNORE_FZF:-} && "$(type fzf &>/dev/null; echo $?)" -eq 0 ]]; then
        VERSION=$(kbenv_list_remote | fzf)
    fi

    if [[ -z "$VERSION" ]]
    then
        echo "You must specify a version!"
        return 1
    fi

    if [[ -e "$KUBECTL_BINARY_PATH/kubectl-$VERSION" ]]
    then
        echo "The version $VERSION is already installed!"
        return 0
    fi

    os_arch=$(_kbenv_get_so_and_arch)
    if [[ "$os_arch" = *"UNKNOWN"* ]]
    then
        echo "The architecture and/or the SO is not supported: $os_arch"
        return 1
    fi

    url="https://storage.googleapis.com/kubernetes-release/release/$VERSION/bin/$os_arch/kubectl"
    echo "Downloading binary..."
    curl -s -L -o "/tmp/kubectl-$VERSION" "$url"

    filetype="$(file -b "/tmp/kubectl-$VERSION")"
    if [[ "$filetype" != *"executable"* ]]
    then
        echo "There was a problem downloading the file! You probably typed the version incorrectly, but it may be something else."
        return 1
    fi

    chmod +x "/tmp/kubectl-$VERSION"
    mv "/tmp/kubectl-$VERSION" "$KUBECTL_BINARY_PATH/kubectl-$VERSION"

    if [[ -L "$KUBECTL_BINARY_PATH/kubectl" ]]
    then
        actual_version="$(basename "$(readlink -f "$KUBECTL_BINARY_PATH/kubectl")")"
        echo "kubectl is pointing to the ${actual_version//kubectl-} version"
        echo "Do you want to overwrite it? (y/n)"
        read -r overwrite
        if [[ "$overwrite" == "y" ]]
        then
            kbenv_use "$VERSION"
        else
            echo "Nothing done, kubectl still points to the ${actual_version//kubectl-} version"
        fi
    else
        kbenv_use "$VERSION"
    fi
}

function kbenv_uninstall(){
    VERSION="$1"

    if [[ -z "$VERSION" ]] && [[ -t 1 && -z ${KBENV_IGNORE_FZF:-} && "$(type fzf &>/dev/null; echo $?)" -eq 0 ]]; then
        VERSION=$(kbenv_list | fzf)
    fi

    if [[ -z "$VERSION" ]]
    then
        echo "You must specify a version!"
        return 1
    fi

    if [[ -e "$KUBECTL_BINARY_PATH/kubectl-$VERSION" ]]
    then
        rm "$KUBECTL_BINARY_PATH/kubectl-$VERSION"
        echo "The version $VERSION is uninstalled!"
    else
        echo "Nothing done, the version $VERSION is not installed!"
    fi
}

function kbenv_list(){
    installed_versions="$(find "${KUBECTL_BINARY_PATH}"/ -name '*kubectl*' -printf '%f\n' | sed -r 's/kubectl-?//' | sed '/^$/d' | sort --version-sort)"
    echo "$installed_versions"
}

function kbenv_use(){
    VERSION="$1"

    if [[ -z "$VERSION" ]] && [[ -t 1 && -z ${KBENV_IGNORE_FZF:-} && "$(type fzf &>/dev/null; echo $?)" -eq 0 ]]; then
        VERSION=$(kbenv_list | fzf)
    fi

    if [[ -z "$VERSION" ]]
    then
        echo "You must specify a version!"
        return 1
    fi

    installed="$(find "$KUBECTL_BINARY_PATH"/ -name "*$VERSION*")"

    if [[ -z "$installed" ]]
    then
        echo "The $VERSION version is not installed!"
        return 1
    fi

    actual_link="$(readlink -f "$KUBECTL_BINARY_PATH/kubectl")"

    if [[ "$actual_link" =~ $VERSION ]]
    then
        echo "kubectl was already pointing to the $VERSION version!"
    else
        ln -sf "$KUBECTL_BINARY_PATH/kubectl-$VERSION" "$KUBECTL_BINARY_PATH/kubectl"
        echo "Done! Now kubectl points to the $VERSION version"
        export KUBECTL_HOME="$HOME/.kubectl/${VERSION}"
    fi
}

function kbenv_help() {
    echo "Usage: kbenv <command> [<options>]"
    echo "Commands:"
    echo "    list-remote   List all installable versions"
    echo "    list          List all installed versions"
    echo "    install       Install a specific version"
    echo "    use           Switch to specific version"
    echo "    uninstall     Uninstall a specific version"
}

function kbenv_init () {
    KUBECTL_BINARY_PATH="$HOME/.bin"

    if [[ ! -e "$KUBECTL_BINARY_PATH" ]]
    then
        mkdir "$KUBECTL_BINARY_PATH"
    fi
}

function kbenv() {
    ACTION="$1"
    ACTION_PARAMETER="$2"

    _kbenv_test_requirements

    case "${ACTION}" in
        "list-remote")
            kbenv_list_remote;;
        "list")
            kbenv_list;;
        "install")
            kbenv_install "$ACTION_PARAMETER";;
        "uninstall")
            kbenv_uninstall "$ACTION_PARAMETER";;
        "use")
            kbenv_use "$ACTION_PARAMETER";;
        *)
            kbenv_help
    esac
}

kbenv_init
