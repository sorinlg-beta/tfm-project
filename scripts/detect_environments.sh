#!/usr/bin/env bash

# test GITHUB_REF is set
if [ -z "${_target_ref}" ]; then
  echo "_target_ref is not set"
  exit 1
fi

# local execution support
if [ -z "${GITHUB_OUTPUT}"]; then
  GITHUB_OUTPUT="/dev/null"
fi

# read tfm config
source .tfm.conf
echo "Config path: ${__tfm_env_rel_path}"
echo "Modules path: ${__tfm_module_rel_path}"

# discover projects
projects=`ls -A ${__tfm_env_rel_path}`
echo
echo "Found projects:"
for project in ${projects}; do
  echo "  - ${project}"
done

# discover modules
modules=`ls -A ${__tfm_module_rel_path}`
echo
echo "Found modules:"
for module in ${modules}; do
  echo "  - ${module}"
done

# discover promotion settings
promotion_settings_path='promotion_settings.yaml'
settings=`cat "${promotion_settings_path}" | yq -o json | jq -c '.'`
echo
echo "Found settings in ${promotion_settings_path}:"
echo "${settings}" | yq -p json

# extract target to branch mapping
target_to_source_refs=$(echo $settings | jq -c '.target_to_source_refs')
echo
echo "Target sources map: ${target_to_source_refs}"

# remove redundant git ref prefix
target_ref="${_target_ref##deploy/}"
echo
echo "Target ref: ${target_ref}"

# extract target envs
matching_target_patterns=$(echo ${target_to_source_refs} | jq -rc --arg target_ref ${target_ref} '. | to_entries | map(select(.value == $target_ref)) | from_entries | keys | join(" ")')
echo
echo "Matching target patterns: ${matching_target_patterns}"

# detect target envs
## create temporary file to store target executions in JSON format
output_file="$(mktemp -t target_executions.json.XXXXXX)"
echo "Output file: ${output_file}"
echo "[]" > "${output_file}"

echo
echo "Scanning for target envs..."
for selected_product in ${projects}; do
  echo "- Scanning project: ${selected_product}"
  for selected_module in ${modules}; do
    echo "  - Scanning module: ${selected_module}"
    for env_pattern_filter in ${matching_target_patterns}; do
      echo "    - Scanning target env pattern: ${env_pattern_filter}"
      detected_envs="$(find "${__tfm_env_rel_path}/${selected_product}" -type d -mindepth 2 -name "${selected_module}" | sed "s,${__tfm_env_rel_path}/${selected_product}/,,g" | sed "s,/${selected_module},,g")"
      for detected_env in ${detected_envs}; do
        if [[ "${detected_env}" == *"${env_pattern_filter}"* ]]; then
          echo "      - Detected target env: ${detected_env}"
          detect_override="$(echo ${target_to_source_refs} | jq --arg _pattern "${detected_env}" '. | to_entries | map(select(.key == $_pattern))')"
          echo -n "        - Detected override:"
          echo "${detect_override}" | jq -c
          found_override=$( test "$(echo "${detect_override}" | jq -r '. | length')" -gt 0 && echo "true" || echo "false" )
          echo "        - Found override: ${found_override}"

          if [ "${found_override}" == "true" ]; then
            override_value="$(echo ${detect_override} | jq -r '.[0].value')"
            override_value_matches_target_ref=$(echo "${override_value}" | grep -q "${target_ref}" && echo "true" || echo "false")
            echo "        - Override value: ${override_value}"
            echo "        - Target ref: ${target_ref}"
            echo "        - Match: ${override_value_matches_target_ref}"

            if [ "${override_value_matches_target_ref}" == "false" ]; then
              echo "        - Override value does not match target ref"
              continue
            fi
          fi

          detected_module_instances="$(ls -A "${__tfm_env_rel_path}/${selected_product}/${detected_env}/${selected_module}" | grep ".*\.tfvars" | grep -v 'tfplan' | sed 's,\.tfvars,,g')"
          for selected_module_instance in ${detected_module_instances}; do
            echo "          - Detected module instance: ${selected_module_instance}"

            # compute target execution
            to_append="$(jq -n -c --arg _product "${selected_product}" --arg _module "${selected_module}" --arg _env "${detected_env}" --arg _module_instance "${selected_module_instance}" '[ { "product": $_product, "module": $_module, "env": $_env, "module_instance": $_module_instance } ]')"
            echo -n "          - Appending: "
            echo "${to_append}" | jq -c

            # append target execution to output file
            jq --argjson _to_append "${to_append}" '. += $_to_append' "${output_file}" > "${output_file}.tmp" && mv "${output_file}.tmp" "${output_file}"
          done

        fi
      done
    done
  done
done

echo
echo "Push to ${target_ref} --> Trigger target executions:"
cat "${output_file}" | jq '.'

# set target executions
target_executions=$(cat "${output_file}" | jq -cr '.')

# set target envs
target_envs=$(echo "${target_executions}" | jq -cr '[.[].env] | sort | unique')

echo
echo "Setting output variables..."
echo "target_executions=${target_executions}" | tee -a $GITHUB_OUTPUT
echo "target_envs=${target_envs}" | tee -a $GITHUB_OUTPUT
