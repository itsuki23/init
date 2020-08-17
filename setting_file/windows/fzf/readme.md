# FZF
pecoみたいなもの

install
```s
$ git clone https://github.com/junegunn/fzf.git
$ ./fzf/install
$ fzf --version
```

add .bashrc
```s
fvim() {
  files=$(git ls-files) &&
  selected_files=$(echo "$files" | fzf -m --preview 'head -100 {}') &&
  vim $selected_files
}
```
https://shingo-sasaki-0529.hatenablog.com/entry/fzf_with_vim

```s
fga() {
  modified_files=$(git status --short | awk '{print $2}') &&
  selected_files=$(echo "$modified_files" | fzf -m --preview 'git diff {}') &&
  git add $selected_files
}
```