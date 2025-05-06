# NOTE: The CIMAN_GIT_REPO_URL will point to 'ci-management' after Phase 1 (dev)

#!/bin/bash
set -eo pipefail

APP_DIR="/app"
CASC_OUTPUT_DIR="/var/jenkins_home/casc.d"

CIMAN_GIT_REPO_URL="https://github.com/lfit/ciman-gitops"
CIMAN_GIT_BRANCH="main"
LOCAL_CIMAN_REPO_PATH="<span class="math-inline">\{APP\_DIR\}/ciman\-gitops\-src"
GLOBAL\_JJB\_REPO\_URL\="https\://github\.com/lfit/global\-jjb"
GLOBAL\_JJB\_GIT\_BRANCH\="master"
LOCAL\_GLOBAL\_JJB\_PATH\="</span>{APP_DIR}/global-jjb-src"
JENKINS_ADMIN_DIR="<span class="math-inline">\{LOCAL\_GLOBAL\_JJB\_PATH\}/jenkins\-admin"
JENKINS\_URL\="http\://localhost\:8080"
log\_message\(\) \{
echo "</span>(date '+%Y-%m-%d %H:%M:%S') - $1"
}

clone_or_update_repo() {
  local repo_url="$1"
  local repo_branch="$2"
  local local_path="$3"
  local repo_name="$4"

  log_message "Cloning/updating ${repo_name} source from ${repo_url} (branch: <span class="math-inline">\{repo\_branch\}\)\.\.\."
if \[ \-d "</span>{local_path}/.git" ]; then
    cd "<span class="math-inline">\{local\_path\}"
git fetch origin "</span>{repo_branch}" --depth 1
    git reset --hard "origin/<span class="math-inline">\{repo\_branch\}"
git submodule update \-\-init \-\-recursive \-\-depth 1
cd "</span>{APP_DIR}"
  else
    rm -rf "<span class="math-inline">\{local\_path\}"
git clone \-\-branch "</span>{repo_branch}" --depth 1 "<span class="math-inline">\{repo\_url\}" "</span>{local_path}"
    cd "<span class="math-inline">\{local\_path\}"
git submodule update \-\-init \-\-recursive \-\-depth 1
cd "</span>{APP_DIR}"
  fi
  log_message "<span class="math-inline">\{repo\_name\} repository updated\."
\}
generate\_jcasc\_files\(\) \{
log\_message "Starting JCasC generation\.\.\."
local jcasc\_input\_path\="</span>{LOCAL_CIMAN_REPO_PATH}/jenkins-configs"
  local python_scripts_path="<span class="math-inline">\{JENKINS\_ADMIN\_DIR\}"
local environment\_flag\=""
if \[\[ "</span>{CIMAN_GIT_BRANCH}" == *"sandbox"* || "${CIMAN_GIT_BRANCH}" == *"dev"* ]]; then
    environment_flag="--sandbox"
  fi

  log_message "Using JCasC input path: ${jcasc_input_path}"
  log_message "Using Python scripts from: ${python_scripts_path}"
  log_message "Environment flag: ${environment_flag}"
  log_message "Outputting JCasC to: ${CASC_OUTPUT_DIR}"

  rm -f <span class="math-inline">\{CASC\_OUTPUT\_DIR\}/\*\.yaml
log\_message "Generating global environment variables\.\.\."
if \[ \-f "</span>{python_scripts_path}/create_jenkins_global_env_vars.py" ]; then
    python3 "<span class="math-inline">\{python\_scripts\_path\}/create\_jenkins\_global\_env\_vars\.py" \\
\-\-path\="</span>{jcasc_input_path}" \
      --outputvars="${CASC_OUTPUT_DIR}/01-global-env-vars.yaml" \
      ${environment_flag}
  else
    log_message "ERROR: create_jenkins_global_env_vars.py not found at <span class="math-inline">\{python\_scripts\_path\}"
fi
log\_message "Generating managed configuration files\.\.\."
if \[ \-f "</span>{python_scripts_path}/create_jenkins_managed_files_yaml.py" ]; then
    python3 "<span class="math-inline">\{python\_scripts\_path\}/create\_jenkins\_managed\_files\_yaml\.py" \\
\-\-path\="</span>{jcasc_input_path}/managed-config-files" \
      --output="${CASC_OUTPUT_DIR}/02-managed-files.yaml" \
      ${environment_flag} \
      --quiet
  else
    log_message "ERROR: create_jenkins_managed_files_yaml.py not found at <span class="math-inline">\{python\_scripts\_path\}"
fi
log\_message "Generating cloud configurations \(example for OpenStack\)\.\.\."
if \[ \-d "</span>{jcasc_input_path}/clouds/openstack" ] && [ -f "<span class="math-inline">\{python\_scripts\_path\}/create\_jenkins\_clouds\_openstack\_yaml\.py" \]; then
python3 "</span>{python_scripts_path}/create_jenkins_clouds_openstack_yaml.py" \
      --path="${jcasc_input_path}" \
      <span class="math-inline">\{environment\_flag\} \\
\-\-name\="default\-openstack" \> "</span>{CASC_OUTPUT_DIR}/03-cloud-openstack.yaml"
  else
    log_message "Skipping OpenStack cloud: config or script not found."
    log_message "Checked for dir: ${jcasc_input_path}/clouds/openstack"
    log_message "Checked for script: ${python_scripts_path}/create_jenkins_clouds_openstack_yaml.py"
  fi

  log_message "JCasC generation complete
