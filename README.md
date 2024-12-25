sudo apt update -y && sudo apt install -y zsh git && chsh -s /bin/zsh "$(whoami)"
chmod +x setup_env.sh
./setup_env.sh