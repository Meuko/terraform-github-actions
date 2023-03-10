#!/bin/bash

function terraformPlan {
  # Gather the output of `terraform plan`.
  echo "plan: info: planning Terraform configuration in ${GITHUB_WORKSPACE}/${tfWorkingDir}"
  planOutput=$(terraform plan -detailed-exitcode -input=false ${*} 2>&1)
  planExitCode=${?}
  planHasChanges=false
  planCommentStatus="Failed"
  planOutputFileSave="${GITHUB_WORKSPACE}/${tfWorkingDir}/plan.txt"
  planOutputFile="${tfWorkingDir}/plan.txt"
  touch "${planOutputFile}"
  echo "set Terraform planExitCode: ${planExitCode}"
  echo "set Terraform tf_cations_plan_output_file to : ${planOutputFile}"
  echo "::set-output name=tf_actions_plan_output_file::${planOutputFile}"

  echo "plan: info: (${planExitCode}) successfully planned Terraform configuration in ${tfWorkingDir}"
  # Exit code of 0 indicates success with no changes. Print the output and exit.
  if [ ${planExitCode} -eq 0 ]; then
    echo "${planOutput}"
    echo
    if echo "${planOutput}" | egrep '^-{72}$' &> /dev/null; then
        planOutput=$(echo "${planOutput}" | sed -n -r '/-{72}/,/-{72}/{ /-{72}/d; p }')
    fi
    planOutput=$(echo "${planOutput}" | sed -r -e 's/^  \+/\+/g' | sed -r -e 's/^  ~/~/g' | sed -r -e 's/^  -/-/g')

    # Save full plan output to a file so it can optionally be added as an artifact
    echo "Current working dir: $PWD"
    pwd

    echo "${planOutput}" > "${planOutputFileSave}"
    echo "Terraform Plan saved to file at : ${planOutputFileSave}"

    # If output is longer than max length (65536 characters), keep last part
    planOutput=$(echo "${planOutput}" | tail -c 65000 )
    echo
    echo ::set-output name=tf_actions_plan_has_changes::${planHasChanges}
    # exit ${planExitCode}
  fi

  # Exit code of 2 indicates success with changes. Print the output, change the
  # exit code to 0, and mark that the plan has changes.
  if [ ${planExitCode} -eq 2 ]; then
    planExitCode=0
    planHasChanges=true
    planCommentStatus="Success"
    echo "${planOutput}"
    echo
    if echo "${planOutput}" | egrep '^-{72}$' &> /dev/null; then
        planOutput=$(echo "${planOutput}" | sed -n -r '/-{72}/,/-{72}/{ /-{72}/d; p }')
    fi
    planOutput=$(echo "${planOutput}" | sed -r -e 's/^  \+/\+/g' | sed -r -e 's/^  ~/~/g' | sed -r -e 's/^  -/-/g')

    # Save full plan output to a file so it can optionally be added as an artifact
    echo "Current working dir: $PWD"
    pwd

    echo "${planOutput}" > "${planOutputFileSave}"
    echo "Terraform Plan saved to file at : ${planOutputFileSave}"

    # If output is longer than max length (65536 characters), keep last part
    planOutput=$(echo "${planOutput}" | tail -c 65000 )
  fi

  # Exit code of !0 indicates failure.
  if [ ${planExitCode} -ne 0 ]; then
    echo "plan: error: failed to plan Terraform configuration in ${tfWorkingDir}"
    echo "${planOutput}"
    echo
  fi

  echo "2 - set Terraform tf_actions_plan_has_changes to ${planHasChanges}"
  echo ::set-output name=tf_actions_plan_has_changes::${planHasChanges}

  # https://github.community/t5/GitHub-Actions/set-output-Truncates-Multiline-Strings/m-p/38372/highlight/true#M3322
  planOutput="${planOutput//'%'/'%25'}"
  planOutput="${planOutput//$'\n'/'%0A'}"
  planOutput="${planOutput//$'\r'/'%0D'}"

  echo "3 - set Terraform tf_actions_plan_output ..."
  echo "::set-output name=tf_actions_plan_output::${planOutput}"
  exit ${planExitCode}
}
