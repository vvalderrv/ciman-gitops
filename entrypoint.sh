#!/bin/bash
set -eo pipefail

APP_DIR="/app"
CASC_OUTPUT_DIR="/var/jenkins_home/casc.d"
GIT_REPO_URL="https://github.com/lfit/ciman-gitops"
GIT_BRANCH="main"
LOCAL_REPO_PATH="${APP_DIR}/ciman-gitops-src"
JENKINS_URL="http://localhost:8080"

log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

clone_or_update_repo() {
  log_message "Cloning/updating JCasC source from ${GIT_REPO_URL} (branch: ${GIT_BRANCH})..."
  if [ -d "${LOCAL_REPO_PATH}/.git" ]; then
    cd "${LOCAL_REPO_PATH}"
    git fetch origin "${GIT_BRANCH}"
    git reset --hard "origin/${GIT_BRANCH}"
    git submodule update --init --recursive
    cd "${APP_DIR}"
  else
    rm -rf "${LOCAL_REPO_PATH}"
    git clone --branch "${GIT_BRANCH}" "${GIT_REPO_URL}" "${LOCAL_REPO_PATH}"
    cd "${LOCAL_REPO_PATH}"
    git submodule update --init --recursive
    cd "${APP_DIR}"
  fi
  log_message "Repository updated."
}

generate_jcasc_files() {
  log_message "Starting JCasC generation..."
  echo "jenkins:" > "${CASC_OUTPUT_DIR}/99-dummy-sidecar.yaml"
  echo "  systemMessage: 'JCasC from sidecar at $(date)'" >> "${CASC_OUTPUT_DIR}/99-dummy-sidecar.yaml"
  log_message "JCasC generation complete. Files placed in ${CASC_OUTPUT_DIR}."
}

reload_jenkins_jcasc() {
  log_message "Attempting to reload Jenkins JCasC via API..."
  log_message "Reload command would be: lftools jenkins -s ${JENKINS_URL} reload-jcasc"
  log_message "Jenkins JCasC reload triggered (simulated)."
}

if [ "$1" == "generate_jcasc" ]; then
  log_message "Cron job triggered: generate_jcasc"
  clone_or_update_repo
  generate_jcasc_files
  reload_jenkins_jcasc
  log_message "Cron job finished."
  exit 0
fi

log_message "Entrypoint started. Handing over to CMD: $@"
exec "$@"
