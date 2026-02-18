#!/bin/bash -eu
# Don't edit this script manually, it comes from https://code.amazon.com/packages/BrazilCLICrossPlatform/blobs/mainline/--/install-scripts/install-mac.sh

# Channel can either be specified as an environment variable (BRAZIL_CLI_CHANNEL)
# or as the first argument to the script.
channel=${BRAZIL_CLI_CHANNEL:-stable}
channel=${1:-$channel}
case $channel in
  stable)
    download_url="https://drive.corp.amazon.com/view/BrazilCLI-2.0/osx/BrazilCLI_2.0-OSX.zip?download=true"
    ;;
  bravehearts)
    download_url="https://brazil-cli-build-osx.aka.amazon.com:8443/job/beta-cli/lastSuccessfulBuild/artifact/*zip*/BrazilCLI_2.0-OSX.zip"
    ;;
  *)
    echo "Invalid channel specified: ${channel}." >&2
    echo "Valid channels are 'stable' and 'bravehearts'" >&2
    exit 1
esac

echo "Checking if brazil needs an update."
if [ -z "$(brazil version 2>&1 | grep 'A new version of Brazil CLI')" ]; then echo "brazil is up to date."; exit 0; fi
echo "Installing BrazilCLI 2.0 ($channel) from $download_url"
(
  set -e
  scratch_dir="$(mktemp -d)"
  cd "${scratch_dir}"

  echo
  echo " -> Downloading installer to ${scratch_dir}/brazilcli.zip"
  curl --fail \
    --negotiate --user : \
    --location \
    --output brazilcli.zip \
    $download_url

  echo
  echo " -> Extracting installer archive"
  unzip -jo brazilcli.zip

  echo
  echo " -> Installing" BrazilCLI-2.0.*.pkg
  sudo installer -allowUntrusted -pkg ./BrazilCLI-2.0.*.pkg -target /

  echo
  echo " -> Cleaning up temporary files"
  rm -rf "${scratch_dir}"

  echo
  echo "Installation complete."
)

if [[ -z "$BRAZIL_CLI_BIN" ]]; then
  echo ""
  echo "Please add the following to your shell configuration file (e.g ~/.zshrc or ~/.bashrc):"
  echo
  echo "export PATH=\$BRAZIL_CLI_BIN:\$PATH"
  echo
  echo "Then log out and log back in (so that \$BRAZIL_CLI_BIN is set),"
  echo "and run 'brazil version' to verify that the CLI was correctly installed."
elif ! which -s brazil; then
  echo
  echo "Please add the following to your shell configuration file (e.g ~/.zshrc or ~/.bashrc):"
  echo
  echo "export PATH=\$BRAZIL_CLI_BIN:\$PATH"
  echo
  echo "Then open a new terminal and verify that you can run 'brazil version'"
else
  version=$(brazil version)
  [ $? -eq 0 ] && echo "You're now successfully running BrazilCLI ${version}"
fi
