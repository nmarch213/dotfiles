
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Homebrew packages
brew update
brew upgrade

# terminal
brew install --cask warp
# terminal theme
brew install starship

# devtools
brew install git
brew install node
brew install pnpm

npm install -g prettier
npm install -g ngrok
npm install -g typescript


# browsers
brew install --cask google-chrome
brew install --cask firefox

# editors
brew install --cask visual-studio-code

# productivity
brew install --cask notion
brew install raycast

# communication
brew install --cask slack
brew install --cask discord

# media
brew install --cask spotify
brew install --cask vlc

# utilities
brew install lastpass-cli

# fonts
brew tap homebrew/cask-fonts
brew install --cask font-fira-code

# GNU core utilities (those that come with OS X are outdated)
brew install coreutils
brew install moreutils
brew install findutils
brew install gnu-sed --with-default-names

# upgrade bash
brew install bash
brew install bash-completion
brew install homebrew/completions/brew-cask-completion

brew cleanup

# install LVIM nightly
bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)






