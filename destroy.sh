#!/usr/bin/env python3

import readline
import os
import sys
import requests

base_dir = "/root"
conf_file = f".conf.env"
github_repo_url = "https://github.com/harrykimpel/otel-k8s-troubleshooting"
github_target_dir = "otel-k8s-troubleshooting"
cluster_name = "instruqt-k3s"
cluster_nr_namespace = "newrelic"
cluster_app_namespace = "default"

# Formatting
bold = "\033[1m"
unbold = "\033[0m"

def load_env(filename):
    
    if os.path.exists(filename):
        with open(conf_file, "r") as f:
            for line in f:
                if line.startswith("NEW_RELIC_LICENSE_KEY"):
                    os.environ["NEW_RELIC_LICENSE_KEY"] = line.split("=")[1].strip()
                elif line.startswith("NEW_RELIC_API_KEY"):
                    os.environ["NEW_RELIC_API_KEY"] = line.split("=")[1].strip()
                elif line.startswith("NEW_RELIC_ACCOUNT_ID"):
                    os.environ["NEW_RELIC_ACCOUNT_ID"] = line.split("=")[1].strip()
                elif line.startswith("NEW_RELIC_REGION"):
                    os.environ["NEW_RELIC_REGION"] = line.split("=")[1].strip()

    
# Load environment variables from conf file if it exists
load_env(conf_file)

# Display input header
header = True

os.environ["TF_VAR_NEW_RELIC_REGION"] = os.environ["NEW_RELIC_REGION"]
os.environ["TF_VAR_NEW_RELIC_ACCOUNT_ID"] = os.environ["NEW_RELIC_ACCOUNT_ID"]
os.environ["TF_VAR_NEW_RELIC_API_KEY"] = os.environ["NEW_RELIC_API_KEY"]

# Terraform Destroy
if os.path.exists("/etc/status_nr_terraform_apply_done"):
    os.chdir(f"{base_dir}/{github_target_dir}/terraform")
    result = os.system("terraform destroy -auto-approve")
    if result == 0:
        print("Terraform apply successful")
        open("/etc/status_nr_terraform_apply_done", "w").close()
    else:
        print("Terraform apply failed")
        print("Please investigate the issue and re-run this process")
        os.chdir(base_dir)
        sys.exit(1)

os.rmdir("/etc/status_nr_terraform_init_done")
os.rmdir("/etc/status_nr_terraform_apply_done")

print(f"\n{bold}New Relic setup destroyed successfully...{unbold}")

# Back to base dir
os.chdir(base_dir)