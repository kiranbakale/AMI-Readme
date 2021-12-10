#!/bin/sh

script_path="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
get_path="/gitlab-environment-toolkit"
get_configs_path="/environments"

for d in $get_configs_path/*; do
  env_dir=$(basename $d)

  if [[ -d "$d/ansible" ]]; then
    printf "Linking $d/ansible to $get_path/ansible/environments/$env_dir\n"
    ln -nsf $d/ansible $get_path/ansible/environments/$env_dir
  fi

  if [[ -d "$d/ansible_inventory" ]]; then
    printf "Linking $d/ansible_inventory to $get_path/ansible/environments/$env_dir\n"
    ln -nsf $d/ansible_inventory $get_path/ansible/environments/$env_dir
  fi

  if [[ -d "$d/terraform" ]]; then
    printf "Linking $d/terraform to $get_path/terraform/environments/$env_dir\n"
    ln -nsf $d/terraform $get_path/terraform/environments/$env_dir
  fi
done

if [[ -d "$get_path/keys" ]]; then
  printf "Linking $get_configs_path/keys/* to $get_path/keys\n"
  ln -nsf $get_configs_path/keys/* $get_path/keys/
fi

if [[ -d "$get_configs_path/modules" ]]; then
  printf "Linking $get_path/terraform/modules to $get_configs_path/modules\n"
  ln -nsf $get_path/terraform/modules $get_configs_path/modules
fi
