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

rerun = False
if os.path.exists("/etc/setupcomplete"):
    print("\nIt looks like setup has already been completed.\n")
    while rerun is False:
            rerun = input(f"Enter {bold}yes{unbold} to re-run setup, or {bold}no{unbold} to exit: ").strip().lower()
            if rerun == "yes" or rerun == "no" or rerun == "y" or rerun == "n":
                break
            print("Invalid response, please try again")
            rerun = False
    if rerun == "no" or rerun == "n": # we are done
        print("Exiting..")
        sys.exit(0)
    
# Load environment variables from conf file if it exists
load_env(conf_file)

# Display input header
header = True

# Set variables from environment variables if they exist
licensekey = os.getenv("NEW_RELIC_LICENSE_KEY", False)
accountid = os.getenv("NEW_RELIC_ACCOUNT_ID", False)
apikey = os.getenv("NEW_RELIC_API_KEY", False)
region = os.getenv("NEW_RELIC_REGION", False)

# If everything loaded from environment variables skip header and go to validation
if licensekey and accountid and apikey and region:
    header = False

# Loop until we have all the information we need
while True:
    if header is True:
        print("\nPlease enter the following information to help us configure your lab environment...\n")
        header = False

    while licensekey is False:
        licensekey = input(f"New Relic {bold}INGEST - LICENSE{unbold} key (should end with \"NRAL\"): ").strip()
        if licensekey.endswith("NRAL"):
            break
        licensekey = False
        print("Invalid, please try again")
    while apikey is False:
        apikey = input(f"New Relic {bold}USER{unbold} key (should start with \"NRAK-\"): ").strip()
        if apikey.startswith("NRAK-"):
            break
        apikey = False
        print("Invalid, please try again")
    while accountid is False:
        accountid = input(f"New Relic {bold}ACCOUNT ID{unbold}: ").strip()
        if accountid.isdigit():
            break
        accountid = False
        print("Invalid, please try again")
    while region is False:
        region = input(f"New Relic {bold}REGION{unbold} (US or EU): ").strip().upper()
        if region == "US" or region == "EU":
            break
        region = False
        print("Invalid, please try again")
    if licensekey and accountid and apikey and region:
        print("\nDoes the following information look correct?\n")
        print(f"New Relic INGEST - LICENSE key: {bold}{licensekey}{unbold}")
        print(f"            New Relic USER key: {bold}{apikey}{unbold}")
        print(f"          New Relic ACCOUNT ID: {bold}{accountid}{unbold}")
        print(f"              New Relic REGION: {bold}{region}{unbold}")
        print("\n")
        confirm = False
        while confirm is False:
            confirm = input(f"Enter {bold}yes{unbold} to confirm and continue setup, or {bold}no{unbold} to re-enter: ").strip().lower()
            if confirm == "yes" or confirm == "no" or confirm == "y" or confirm == "n":
                break
            print("Invalid response, please try again")
            confirm = False
        if confirm == "yes" or confirm == "y": # we are done
            break
        else:
            header = True
            licensekey = False
            accountid = False
            apikey = False
            region = False
            confirm = False

with open(conf_file, "w") as f:
    f.write(f"NEW_RELIC_LICENSE_KEY={licensekey}\n")
    f.write(f"NEW_RELIC_API_KEY={apikey}\n")
    f.write(f"NEW_RELIC_ACCOUNT_ID={accountid}\n")
    f.write(f"NEW_RELIC_REGION={region}\n")
                  
print(f"\n{bold}Starting New Relic setup...{unbold}")

# Reload environment variables
load_env(conf_file)

# Download and install New Relic CLI
if not os.path.exists("/etc/status_nr_cli_done"):
    print("\nDownloading New Relic CLI")
    install_cli_url = "https://download.newrelic.com/install/newrelic-cli/scripts/install.sh"
    response = requests.get(install_cli_url)
    with open("install.sh", "wb") as f:
        f.write(response.content)
    os.chmod("install.sh", 0o755)
    result = os.system("./install.sh")
    if result == 0:
        print("Installation of New Relic CLI successful")
        open("/etc/status_nr_cli_done", "w").close()
    else:
        print("Installation of New Relic CLI failed")
        print("Please investigate the issue and re-run this process")
        sys.exit(1)

# Install New Relic Kubernetes integration
# if not os.path.exists("/etc/status_nr_k8s_done"):
#     print("\nInstalling New Relic Kubernetes integration")
#     result = os.system(f"NEW_RELIC_CLI_SKIP_CORE=1 NR_CLI_CLUSTERNAME={cluster_name} NR_CLI_NAMESPACE={cluster_nr_namespace} NR_CLI_PRIVILEGED=true NR_CLI_LOW_DATA_MODE=true NR_CLI_KSM=true NR_CLI_KUBE_EVENTS=true NR_CLI_PROMETHEUS_AGENT=true NR_CLI_PROMETHEUS_AGENT_LOW_DATA_MODE=true NR_CLI_CURATED=true NEW_RELIC_API_KEY={os.environ['NEW_RELIC_API_KEY']} NEW_RELIC_ACCOUNT_ID={os.environ['NEW_RELIC_ACCOUNT_ID']} /usr/local/bin/newrelic install -n kubernetes-open-source-integration 2>&1")
#     if result == 0:
#         print("Installation of New Relic Kubernetes integration successful")
#         open("/etc/status_nr_k8s_done", "w").close()
#     else:
#         print("Installation of New Relic Kubernetes integration failed")
#         print("Please investigate the issue and re-run this process")
#         sys.exit(1)

# Clone github repo
# if not os.path.exists("/etc/status_github_clone_done"):
#     print("\nCloning github repo containing microservices-demo")
#     result = os.system(f"git clone {github_repo_url} {github_target_dir}")
#     if result == 0:
#         print("Cloning of github repo successful")
#         open("/etc/status_github_clone_done", "w").close()
#     else:
#         print("Cloning of github repo failed")
#         print("Please investigate the issue and re-run this process")
#         sys.exit(1)

# Deploy microservices to Kubernetes
# if not os.path.exists("/etc/status_microservices_deployed"):
#     print("\nDeploying microservices to Kubernetes cluster")
#     os.chdir(f"{base_dir}/{github_target_dir}")
#     result = os.system("./deploy")
#     if result == 0:
#         print("Deployment of microservices successful")
#         open("/etc/status_microservices_deployed", "w").close()
#     else:
#         print("Deployment of microservices failed")
#         print("Please investigate the issue and re-run this process")
#         os.chdir(base_dir)
#         sys.exit(1)

# Wait for frontend microservice to be ready
# print("\nWaiting up to 180 seconds for frontend microservice to be ready")
# result = os.system(f"kubectl -n {cluster_app_namespace} wait --for=condition=ready pod -l app=frontend --timeout=180s")
# if result == 0:
#     print("Frontend microservice is ready")
# else:
#     print("Frontend microservice failed to become ready")
#     print("Please investigate the issue and re-run this process")
#     sys.exit(1)

os.environ["TF_VAR_NEW_RELIC_REGION"] = os.environ["NEW_RELIC_REGION"]
os.environ["TF_VAR_NEW_RELIC_ACCOUNT_ID"] = os.environ["NEW_RELIC_ACCOUNT_ID"]
os.environ["TF_VAR_NEW_RELIC_API_KEY"] = os.environ["NEW_RELIC_API_KEY"]

# Setup New Relic Key Transactions
# if not os.path.exists("/etc/status_nr_key_transactions_done"):
#     print("\nSetting up New Relic Key Transactions")
#     os.chdir(f"{base_dir}/{github_target_dir}")
#     result = os.system("python3 KeyTransactions.py")
#     if result == 0:
#         print("Key Transactions setup successful")
#         open("/etc/status_nr_key_transactions_done", "w").close()
#     else:
#         print("Key Transactions setup failed")
#         print("Please investigate the issue and re-run this process")
#         os.chdir(base_dir)
#         sys.exit(1)

# Setup New Relic with Terraform
if not os.path.exists("/etc/status_nr_terraform_init_done"):
    print("\nSetting up New Relic Workloads, SLOs and Alerts with Terraform")
    os.chdir(f"{base_dir}/{github_target_dir}/terraform")
    result = os.system("terraform init")
    if result == 0:
        print("Terraform init successful")
        open("/etc/status_nr_terraform_init_done", "w").close()
    else:
        print("Terraform init failed")
        print("Please investigate the issue and re-run this process")
        os.chdir(base_dir)
        sys.exit(1)

if not os.path.exists("/etc/status_nr_terraform_apply_done"):
    os.chdir(f"{base_dir}/{github_target_dir}/terraform")
    result = os.system("terraform apply -auto-approve")
    if result == 0:
        print("Terraform apply successful")
        open("/etc/status_nr_terraform_apply_done", "w").close()
    else:
        print("Terraform apply failed")
        print("Please investigate the issue and re-run this process")
        os.chdir(base_dir)
        sys.exit(1)

# Touch file to indicate that setup has been completed
open("/etc/setupcomplete", "w").close()

print(f"\n{bold}New Relic setup completed successfully...{unbold}")

# Back to base dir
os.chdir(base_dir)
