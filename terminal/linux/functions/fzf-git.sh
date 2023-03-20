# The MIT License (MIT)
#
# Copyright (c) 2022 Junegunn Choi
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

if [[ $# -eq 1 ]]; then
  branches() {
    git branch "$@" --sort=-committerdate --sort=-HEAD --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=always | column -ts$'\t'
  }
  refs() {
    git for-each-ref --sort=-creatordate --sort=-HEAD --color=always --format=$'%(refname) %(color:green)(%(creatordate:relative))\t%(color:blue)%(subject)%(color:reset)' |
      eval "$1" |
      sed 's#^refs/remotes/#\x1b[95mremote-branch\t\x1b[33m#; s#^refs/heads/#\x1b[92mbranch\t\x1b[33m#; s#^refs/tags/#\x1b[96mtag\t\x1b[33m#; s#refs/stash#\x1b[91mstash\t\x1b[33mrefs/stash#' |
      column -ts$'\t'
  }
  case "$1" in
    branches)
      echo $'CTRL-O (open in browser) ╱ ALT-A (show all branches)\n'
      branches
      ;;
    all-branches)
      echo $'CTRL-O (open in browser)\n'
      branches -a
      ;;
    refs)
      echo $'CTRL-O (open in browser) ╱ ALT-E (examine in editor) ╱ ALT-A (show all refs)\n'
      refs 'grep -v ^refs/remotes'
      ;;
    all-refs)
      echo $'CTRL-O (open in browser) ╱ ALT-E (examine in editor)\n'
      refs 'cat'
      ;;
    nobeep) ;;
    *) exit 1 ;;
  esac
elif [[ $# -gt 1 ]]; then
  set -e

  branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
  if [[ $branch = HEAD ]]; then
    branch=$(git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)
  fi

  # Only supports GitHub for now
  case "$1" in
    commit)
      hash=$(grep -o "[a-f0-9]\{7,\}" <<< "$2")
      path="/commit/$hash"
      ;;
    branch|remote-branch)
      branch=$(sed 's/^[* ]*//' <<< "$2" | cut -d' ' -f1)
      remote=$(git config branch."${branch}".remote || echo 'origin')
      branch=${branch#$remote/}
      path=/tree/$branch
      ;;
    remote)
      remote=$2
      path=/tree/$branch
      ;;
    file) path=/blob/$branch/$(git rev-parse --show-prefix)$2 ;;
    tag)  path=/releases/tag/$2 ;;
    *)    exit 1 ;;
  esac

  remote=${remote:-$(git config branch."${branch}".remote || echo 'origin')}
  remote_url=$(git remote get-url "$remote" 2> /dev/null || echo "$remote")

  if [[ $remote_url =~ ^git@ ]]; then
    url=${remote_url%.git}
    url=${url#git@}
    url=https://${url/://}
  elif [[ $remote_url =~ ^http ]]; then
    url=${remote_url%.git}
  fi

  case "$(uname -s)" in
    Darwin) open "$url$path"     ;;
    *)      xdg-open "$url$path" ;;
  esac
  exit 0
fi

