#!/usr/bin/env bash


set -uo pipefail

if [ "$#" -ne 1 ] || ! [ -d "$1" ]; then
  echo "Usage: $0 ROOT_DIRECTORY_OF_FRAMEWORK" >&2
  exit 1
fi
root_dir="${1}";

function main
{
    echo -n "Initializing your environments' configuration files... "
    echo -n "please enter project prefix: " >&2
    read project_prefix
    echo -n "please enter app name: " >&2
    read app_name
    echo -n "please enter github org: " >&2
    read github_org
    echo -n "please enter github repo name: " >&2
    read github_repo
    echo "" >&2

    echo "${app_name}" >${root_dir}/.app_name

    echo "entered values are: " 1>&2 >&2
    echo "- project_prefix: ${project_prefix}" >&2
    echo "- app_name: ${app_name}" >&2
    echo "" >&2
    echo "calculated project are: " >&2
    echo "- dv: ${project_prefix}-dv" >&2
    echo "- qa: ${project_prefix}-qa" >&2
    echo "- np: ${project_prefix}-np" >&2
    echo "- pd: ${project_prefix}-pd" >&2

    echo "generating json configuration files..." >&2
    for file_name in ${root_dir}/environments/*.json.template;
    do
        if [ "${file_name}" == "${root_dir}/environments/sbx.json.template" ]; then
            continue
        fi
        name=$(sed 's/.template//' <<< ${file_name})
        sed -e '/##.*$/d' \
            -e "s/<project_prefix>/${project_prefix}/" \
            -e "s/<app_name_short>/${app_name//-/}/" \
            -e "s/<github_org>/${github_org}/" \
            -e "s/<github_repo>/${github_repo}/" \
            ${file_name} \
        > ${name}
    done;
    echo "generation of json configuration files is over." >&2
}

main
