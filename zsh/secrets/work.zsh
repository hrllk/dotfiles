load_work_keys() {
  __export_secret FIGMA_TOKEN "$DOTFILES_KEY_DIR/figma-token"
  __export_secret CONFLUENCE_TOKEN "$DOTFILES_KEY_DIR/work/confluence"
}

load_oke_vars() {
  local key_dir="${DOTFILES_WORK_KEY_DIR:-$DOTFILES_KEY_DIR/work}"

  __export_secret DC_TRB_PRD "$key_dir/dc_trb_prd"
  __export_secret DC_TRB_STG "$key_dir/dc_trb_stg"
  __export_secret DC_TRB_DEV "$key_dir/dc_trb_dev"
}
