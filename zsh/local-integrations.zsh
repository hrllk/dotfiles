export LANG='en_US.UTF-8'
export LC_ALL=en_US.UTF-8

set -o vi

___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"
if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then
  . "${___MY_VMOPTIONS_SHELL_FILE}"
fi
