#!/bin/bash
# NOTE: The CIMAN_GIT_REPO_URL will point to 'ci-management' after Phase 1 (dev)

set -eo pipefail

APP_DIR="/app"
CASC_OUTPUT_DIR="/var/jenkins_home/casc.d"

GLOBAL_JJB_REPO_URL="https://github.com/lfit/global-jjb"
GLOBAL_JJB_GIT_BRANCH="master"
LOCAL_GLOBAL_JJB_PATH="${APP_DIR}/global-jjb-src"
JENKINS_ADMIN_DIR="${LOCAL_GLOBAL_JJB_PATH}/jenkins-admin"
JENKINS_URL="http://localhost:8080"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

clone_or_update_repo() {
  local repo_url="$1"
  local repo_branch="$2"
  local local_path="$3"
  local repo_name="$4"

  log_message "Cloning/updating ${repo_name} source from ${repo_url} (branch: ${repo_branch})..."
  if [ -d "${local_path}/.git" ]; then
    cd "${local_path}" || exit
    git fetch origin "${repo_branch}" --depth 1
    git reset --hard "origin/${repo_branch}"
    git submodule update --init --recursive --depth 1
    cd "${APP_DIR}" || exit
  else
    rm -rf "${local_path}"
    git clone --branch "${repo_branch}" --depth 1 "${repo_url}" "${local_path}"
    cd "${local_path}" || exit
    git submodule update --init --recursive --depth 1
    cd "${APP_DIR}" || exit
  fi
  log_message "${repo_name} repository updated."
}

generate_jcasc_files() {
  log_message "Starting JCasC generation..."
  local jcasc_input_path="/app/jenkins-config" 
  local python_scripts_path="${JENKINS_ADMIN_DIR}"
  local environment_flag="" # This may need adjustment based on env var availability

  log_message "Using JCasC input path: ${jcasc_input_path}"
  log_message "Using Python scripts from: ${python_scripts_path}"
  log_message "Environment flag: ${environment_flag}"
  log_message "Outputting JCasC to: ${CASC_OUTPUT_DIR}"

  mkdir -p "${CASC_OUTPUT_DIR}"
  rm -f ${CASC_OUTPUT_DIR}/*.yaml

  log_message "Generating global environment variables..."
  if [ -f "${python_scripts_path}/create_jenkins_global_env_vars.py" ]; then
    python3 "${python_scripts_path}/create_jenkins_global_env_vars.py" \
      --path="${jcasc_input_path}" \
      --outputvars="${CASC_OUTPUT_DIR}/01-global-env-vars.yaml" \
      ${environment_flag}
  else
    log_message "ERROR: create_jenkins_global_env_vars.py not found at ${python_scripts_path}"
  fi

  log_message "Generating managed configuration files..."
  if [ -f "${python_scripts_path}/create_jenkins_managed_files_yaml.py" ]; then
    python3 "${python_scripts_path}/create_jenkins_managed_files_yaml.py" \
      --path="${jcasc_input_path}/managed-config-files" \
      --output="${CASC_OUTPUT_DIR}/02-managed-files.yaml" \
      ${environment_flag} \
      --quiet
  else
    log_message "ERROR: create_jenkins_managed_files_yaml.py not found at ${python_scripts_path}"
  fi

  log_message "Generating cloud configurations (example for OpenStack)..."
  if [ -d "${jcasc_input_path}/clouds/openstack" ] && [ -f "${python_scripts_path}/create_jenkins_clouds_openstack_yaml.py" ]; then
    python3 "${python_scripts_path}/create_jenkins_clouds_openstack_yaml.py" \
      --path="${jcasc_input_path}" \
      ${environment_flag} \
      --name="default-openstack" > "${CASC_OUTPUT_DIR}/03-cloud-openstack.yaml"
  else
    log_message "Skipping OpenStack cloud: config or script not found."
  fi

  log_message "JCasC generation complete."
}

log_message "Entrypoint script started."
clone_or_update_repo "${GLOBAL_JJB_REPO_URL}" "${GLOBAL_JJB_GIT_BRANCH}" "${LOCAL_GLOBAL_JJB_PATH}" "global-jjb"
generate_jcasc_files
log_message "JCasC files generated."

log_message "Handing over to CMD: $@"
exec "$@"
