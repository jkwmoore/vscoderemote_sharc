# VSCode Remote HPC

This script can be used to start a batch job on the cluster and then connect Microsoft VSCode to it. The script is inspired by the blog 

https://medium.com/@isaiah.taylor/use-vs-code-on-a-supercomputer-15e4cbbb1bc2

##Preparation

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

## Using the script

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
