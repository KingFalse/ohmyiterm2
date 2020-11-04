#!/bin/bash

sudo -v

GITHUB_URL="https://codeload.github.com/KingFalse/ohmyiterm2/zip/master"
ALIYUN_URL="https://code.aliyun.com/kar/ohmyiterm2/repository/archive.zip?ref=master"

case $1 in
"aliyun")
  URL=$ALIYUN_URL
  ;;
"github")
  URL=$GITHUB_URL
  ;;
*)
  echo "您想从阿里云下载还是从GitHub下载"
  echo "(1:阿里云 2:GitHub)"
  read -p "默认1:阿里云:"
  case $num in
  2)
    echo "您选择从GitHub下载..."
    URL=$GITHUB_URL
    ;;
  *)
    echo "您选择了从阿里云下载..."
    URL=$ALIYUN_URL
    ;;
  esac
  ;;
esac

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

have_sudo_access() {
  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
    /usr/bin/sudo -l mkdir &>/dev/null
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ -z "${HOMEBREW_ON_LINUX-}" ]] && [[ "$HAVE_SUDO_ACCESS" -ne 0 ]]; then
    abort "Need sudo access on macOS!"
  fi

  return "$HAVE_SUDO_ACCESS"
}

execute_sudo() {
  local -a args=("$@")
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A" "${args[@]}")
  fi
  if have_sudo_access; then
    execute "/usr/bin/sudo" "${args[@]}"
  else
    execute "${args[@]}"
  fi
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

function clearAll() {
  echo "清理安装缓存文..."
  sudo rm -rf ~/ohmyiterm2
}

echo "创建/usr/local/bin"
sudo mkdir -p /usr/local/bin
mkdir -p ~/.iterm2/zmodem

echo "正在下载所需文件..."
# curl --location --request GET "$URL" --output "$HOME/ohmyiterm2.zip"
# unzip -o -q ~/ohmyiterm2.zip -d ~/
# rm -rf ~/ohmyiterm2.zip
mv ~/ohmyiterm2* ~/ohmyiterm2
cd ~/ohmyiterm2
cp ~/ohmyiterm2/iterm2-*-zmodem.sh ~/.iterm2/zmodem
cp ~/ohmyiterm2/iterm2-*-zmodem.sh ~/.iterm2/zmodem
chmod 777 ~/.iterm2/zmodem/*

echo "开始安装ohmyzsh..."
unzip -o -q ~/ohmyiterm2/ohmyzsh-master.zip -d ~/.oh-my-zsh
cat ~/.oh-my-zsh/tools/install.sh | sed -e 's/setup_ohmyzsh$//g' | sed -e 's/-d "$ZSH"/-d "NULL"/g' | bash

#安装插件
echo "开始安装ohmyzsh插件git-open..."
tar -zxf ~/ohmyiterm2/git-open-*.tar.gz -C ~/.oh-my-zsh/plugins/
echo "开始安装ohmyzsh插件zsh-autosuggestions..."
tar -zxf ~/ohmyiterm2/zsh-autosuggestions-0.6.4.tar.gz -C ~/.oh-my-zsh/plugins/
echo "开始安装ohmyzsh插件zsh-syntax-highlighting..."
tar -zxf ~/ohmyiterm2/zsh-syntax-highlighting-0.7.1.tar.gz -C ~/.oh-my-zsh/plugins/
echo "开始安装ohmyzsh插件autojump..."
unzip -o -q ~/ohmyiterm2/autojump-release-v22.5.3.zip -d ~/ohmyiterm2
cd ~/ohmyiterm2/autojump-release-v22.5.3 && python install.py > /dev/null
echo "[[ -s $HOME/.autojump/etc/profile.d/autojump.sh ]] && source $HOME/.autojump/etc/profile.d/autojump.sh" >> ~/.zshrc
echo "autoload -U compinit && compinit -u" >> ~/.zshrc

cd ~/.oh-my-zsh/plugins/
mv git-open* git-open
mv zsh-autosuggestions* zsh-autosuggestions
mv zsh-syntax-highlighting* zsh-syntax-highlighting
echo "正在开启ohmyzsh插件..."
sed -i "" 's/^plugins.*$/plugins=(git cp git-open autojump extract zsh-syntax-highlighting zsh-autosuggestions)/g' ~/.zshrc

echo "开始安装starship..."
sudo tar -zxf ~/ohmyiterm2/starship-x86_64-apple-darwin*.tar.gz -C /usr/local/bin
echo "eval \"\$(starship init zsh)\"" >>~/.zshrc

echo "正在配置Iterm2..."
cp ~/ohmyiterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist

echo "正在安装字体..."
sudo unzip -o -q ~/ohmyiterm2/Hack.zip -d /Library/Fonts

echo "正在安装iTerm2..."
sudo unzip -o -q ~/ohmyiterm2/iTerm2*.zip -d /Applications

echo "正在安装iTerm2-Utilities扩展..."
sudo unzip -o -q ~/ohmyiterm2/utilities.zip -d ~/.iterm2
chmod +x ~/.iterm2/*

echo "test -e ~/.iterm2_shell_integration.zsh && source ~/.iterm2_shell_integration.zsh" >>~/.zshrc
cp ~/ohmyiterm2/.iterm2_shell_integration.zsh ~/
chmod +x ~/.iterm2_shell_integration.zsh

# 检测CommandLineTools是否已经安装
if ! [ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
  echo "正在安装CommandLineTools，苹果官网下载会比较慢，请稍候..."
  clt_placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  execute_sudo "/usr/bin/touch" "$clt_placeholder"

  clt_label_command="/usr/sbin/softwareupdate -l |
                      grep -B 1 -E 'Command Line Tools' |
                      awk -F'*' '/^ *\\*/ {print \$2}' |
                      sed -e 's/^ *Label: //' -e 's/^ *//' |
                      sort -V |
                      tail -n1"
  clt_label="$(chomp "$(/bin/bash -c "$clt_label_command")")"

  if [[ -n "$clt_label" ]]; then
    echo "Installing $clt_label"
    execute_sudo "/usr/sbin/softwareupdate" "-i" "$clt_label"
    execute_sudo "/bin/rm" "-f" "$clt_placeholder"
    execute_sudo "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
  fi
fi

if ! [ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
  echo "CommandLineTools安装失败，请稍后重新允许此脚本安装，您也可以执行xcode-select --install手动安装CommandLineTools后重新执行本脚本"
  clearAll
  exit
fi

if ! [ -x "$(command -v sz)" ]; then
  echo "开始编译安装lrzsz..."
  tar -xvf ~/ohmyiterm2/lrzsz-*.tar.gz -C ~/ohmyiterm2/
  rm -rf ~/ohmyiterm2/lrzsz-*.tar.gz
  cd ~/ohmyiterm2/lrzsz-*
  ./configure --quiet --prefix=/usr/local/lrzsz
  sudo make -s
  sudo make install -s
  sudo ln -s /usr/local/lrzsz/bin/lrz /usr/local/bin/rz
  sudo ln -s /usr/local/lrzsz/bin/lsz /usr/local/bin/sz
fi

if ! [ -x "$(command -v sshpass)" ]; then
  echo "开始编译安装sshpass..."
  tar -xvf ~/ohmyiterm2/sshpass-*.tar.gz -C ~/ohmyiterm2/
  rm -rf ~/ohmyiterm2/sshpass-*.tar.gz
  cd ~/ohmyiterm2/sshpass-*
  ./configure --disable-dependency-tracking
  sudo make install -s
fi
clearAll

echo "刷新环境变量..."
source ~/.zshrc >/dev/null 2>&1
