load_oke_vars() {
  local key_dir="$HOME/Library/Mobile Documents/com~apple~CloudDocs/task/keys/work"

  __export_secret DC_TRB_PRD "$key_dir/dc_trb_prd"
  __export_secret DC_TRB_STG "$key_dir/dc_trb_stg"
  __export_secret DC_TRB_DEV "$key_dir/dc_trb_dev"
}
