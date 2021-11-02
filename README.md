# VSCode Remote HPC

This script can be used to start a batch job on the cluster and then connect Microsoft VSCode to it. The script is inspired by the blog 

https://medium.com/@isaiah.taylor/use-vs-code-on-a-supercomputer-15e4cbbb1bc2

## Requirements

The script assumes that you have setup SSH keys for passwordless access to the cluster. Please find some instructions on how to create SSH keys on the scicomp wiki:

https://scicomp.ethz.ch/wiki/Accessing_the_clusters#SSH_keys

Currently the script runs on Linux, Mac OS X and Windows (using WSL/WSL2 or git bash). When using a Linux computer, please make sure that xdg-open is installed. This package is used to automatically start your default browser. You can install it with the command

CentOS:

```
yum install xdg-utils
```

Ubuntu:

```
apt-get install xdg-utils
```

## Using SSH keys with non-default names
Since the reopening of Euler after the cyber attack in May 2020, we recommend to the cluster users to use SSH keys.
```
$HOME/.ssh/id_ed25519_euler
```

You can either use the -k option of the script to specify the location of the SSH key, or even better use an SSH config file with the IdentityFile option

https://scicomp.ethz.ch/wiki/Accessing_the_clusters#How_to_use_keys_with_non-default_names

I would recommend to use the SSH config file as this works more reliably.

## Preparation

The preparation steps only need to be executed once. You need to carry out those steps to set up the basic configuration for your ETH account with regards to the code-server.

* Login to the Euler
* Start and interactive job with

```
bsub -Is -W 0:10 -n 1 -R "rusage[mem=2048]" bash
```

When using Euler, switch to the new software stack (in case you haven't set it as default yet), either using

```
env2lmod
```

for the current shell, or

```
set_software_stack.sh new
```

to set it as permanent default (when using this command, you need to logout and login again to make the change becoming active)

Load the modules for one of the code-server installations:

```
module load gcc/6.3.0 code-server/3.12.0
```

Start the code-server once with the command code-server

```
[sfux@eu-ms-001-01 ~]$ code-server
[2021-11-02T10:01:45.407Z] info  code-server 3.12.0 4cd55f94c0a72f05c18cea070e10b969996614d2
[2021-11-02T10:01:45.409Z] info  Using user-data-dir ~/.local/share/code-server
[2021-11-02T10:01:45.433Z] info  Using config file ~/.config/code-server/config.yaml
[2021-11-02T10:01:45.433Z] info  HTTP server listening on http://127.0.0.1:8080
[2021-11-02T10:01:45.433Z] info    - Authentication is enabled
[2021-11-02T10:01:45.433Z] info      - Using password from ~/.config/code-server/config.yaml
[2021-11-02T10:01:45.433Z] info    - Not serving HTTPS
[sfux@eu-ms-001-01 ~]$ 
```

This will setup the local configuration (including a password for you) and store it in your home directory in $HOME/.config/code-server/config.yaml

After the server started, terminate it with ctrl+c

## Usage

### Install

Download the repository with the commnad

```
git clone https://gitlab.ethz.ch/sfux/VSCode_remote_HPC
```

Mac OS X:

```
git clone https://gitlab.ethz.ch/sfux/VSCode_remote_HPC.git
```

### Run VSCode in a batch job

The start_vscode.sh script needs to be executed on your local computer. Please find below the list of options that can be used with the script:

```
$ ./start_vscode.sh --help
./start_vscode.sh: Script to start a VSCode on Euler from a local computer

Usage: start_vscode.sh [options]

Options:

        -u | --username       USERNAME         ETH username for SSH connection to Euler
        -n | --numcores       NUM_CPU          Number of CPU cores to be used on the cluster
        -W | --runtime        RUN_TIME         Run time limit for the code-server in hours and minutes HH:MM
        -m | --memory         MEM_PER_CORE     Memory limit in MB per core

Optional arguments:

        -c | --config         CONFIG_FILE      Configuration file for specifying options
        -g | --numgpu         NUM_GPU          Number of GPUs to be used on the cluster
        -h | --help                            Display help for this script and quit
        -i | --interval       INTERVAL         Time interval for checking if the job on the cluster already started
        -k | --key            SSH_KEY_PATH     Path to SSH key with non-standard name
        -v | --version                         Display version of the script and exit

Examlples:

        ./start_vscode.sh -u sfux -n 4 -W 04:00 -m 2048

        ./start_vscode.sh --username sfux --numcores 2 --runtime 01:30 --memory 2048

        ./start_vscode.sh -c /c/Users/sfux/.vsc_config

Format of configuration file:

VSC_USERNAME=""             # ETH username for SSH connection to Euler
VSC_NUM_CPU=1               # Number of CPU cores to be used on the cluster
VSC_NUM_GPU=0               # Number of GPUs to be used on the cluster
VSC_RUN_TIME="01:00"        # Run time limit for the code-server in hours and minutes HH:MM
VSC_MEM_PER_CPU_CORE=1024   # Memory limit in MB per core
VSC_WAITING_INTERVAL=60     # Time interval to check if the job on the cluster already started
VSC_SSH_KEY_PATH=""         # Path to SSH key with non-standard name
```

### Reconnect to a code-server session
When running the script, it creates a local file called reconnect_info in the installation directory, which contains all information regarding the used ports, the remote ip address, the command for the SSH tunnel and the URL for the browser. This information should be sufficient to reconnect to a code-server session if connection was lost.

## Cleanup after the job
Please note that when you finish working with the code-server, you need to login to the cluster, identify the job with bjobs and then kill it with the bkill command, using the jobid as parameter). Afterwards you also need to clean up the SSH tunnel that is running in the background. Example:

```
$ ps -u | grep -m1 -- "-L" | grep -- "-N"
samfux    8729  0.0  0.0  59404  6636 pts/5    S    13:46   0:00 ssh sfux@euler.ethz.ch -L 51339:10.205.4.122:8888 -N
$ kill 8729
```

This example is from a Linux computer. If you are using git bash on Windows, then you can find the SSH process with the ps kommand and use kill to stop it.

## Main author
* Samuel Fux

## Contributions
* Andreas Lugmayr
