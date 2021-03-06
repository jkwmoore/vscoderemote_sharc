# VSCode Remote HPC

This script can be used to start a batch job on the cluster and then connect Microsoft VSCode to it. The script is inspired by the blog 

https://medium.com/@isaiah.taylor/use-vs-code-on-a-supercomputer-15e4cbbb1bc2

This version has been forked from the (much appreciated) original at https://gitlab.ethz.ch/sfux/VSCode_remote_HPC

## Requirements

The script assumes that you have setup SSH keys for passwordless access to the cluster. Please find some instructions on how to create SSH keys below:

https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-22-04

Currently the script should run on Linux (tested on Ubuntu), Mac OS X (untested) and Windows (using WSL/WSL2 or git bash also untested). When using a Linux computer, please make sure that xdg-open is installed. This package is used to automatically start your default browser. You can install it with the command

CentOS:

```
yum install xdg-utils
```

Ubuntu:

```
apt-get install xdg-utils
```

You can either use the -k option of the script to specify the location of the SSH key, or even better use an SSH config file with the IdentityFile option by adding the following lines in your $HOME/.ssh/config file: 

```
 Host sharc.shef.ac.uk
 IdentityFile ~/.ssh/id_ed25519_sharc
```

## Preparation

The preparation steps only need to be executed once. You need to carry out those steps to set up the basic configuration for your ShARC account with regards to the code-server.

* Login to the ShARC cluster
* Start and interactive job with

```
qrshx
```
Load the modules for one of the code-server installations:

```
module load apps/vscode-server/4.2.0/binary
```

Start the code-server once with the command code-server

```
[te1st@sharc.shef.ac.uk ~]$ code-server
[2022-04-04T10:01:45.407Z] info  code-server 4.2.0
[2022-04-04T10:01:45.409Z] info  Using user-data-dir ~/.local/share/code-server
[2022-04-04T10:01:45.433Z] info  Using config file ~/.config/code-server/config.yaml
[2022-04-04T10:01:45.433Z] info  HTTP server listening on http://127.0.0.1:8080
[2022-04-04T10:01:45.433Z] info    - Authentication is enabled
[2022-04-04T10:01:45.433Z] info      - Using password from ~/.config/code-server/config.yaml
[2022-04-04T10:01:45.433Z] info    - Not serving HTTPS
[te1st@sharc.shef.ac.uk ~]$ 
```

This will setup the local configuration (including a password for you) and store it in your home directory in $HOME/.config/code-server/config.yaml

After the server started, terminate it with Ctrl+C

Now generate your SSL certificates (these secure the communications between your local device and the endpoint node.)

```
[te1st@sharc.shef.ac.uk ~]$ setup_ssl_ca_server_client.sh
```



## Usage

### Install

Download the repository with the command

```
git clone git@github.com:jkwmoore/vscoderemote_sharc.git
```

### Run VSCode in a batch job

The start_vscode.sh script needs to be executed on your local computer. Please find below the list of options that can be used with the script:

```
$ ./start_vscode.sh --help
./start_vscode.sh: Script to start a VSCode remote server on ShARC from a local computer

Usage: start_vscode.sh [options]

Options:

        -u | --username       USERNAME         TUoS username for SSH connection to ShARC
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

Examples:

        ./start_vscode.sh -u te1st -n 4 -W 04:00:00 -m 2048

        ./start_vscode.sh --username te1st --numcores 2 --runtime 01:30:00 --memory 2048

        ./start_vscode.sh -c /home/te1st/.vsc_config

Format of configuration file:

VSC_USERNAME=""             # TUoS username for SSH connection to ShARC
VSC_NUM_CPU=1               # Number of CPU cores to be used on the cluster
VSC_NUM_GPU=0               # Number of GPUs to be used on the cluster
VSC_RUN_TIME="01:00:00"     # Run time limit for the code-server in hours and minutes HH:MM:SS
VSC_MEM_PER_CPU_CORE=1024   # Memory limit in MB per core
VSC_WAITING_INTERVAL=60     # Time interval to check if the job on the cluster already started
VSC_SSH_KEY_PATH=""         # Path to SSH key with non-standard name
```

Once a session starts the code-server password is randomly regenerated and the new password will be supplied to you in the terminal alongside the SSL certificate fingerprints. Before clicking past the SSL warning (as the generated certificates are not trusted by default) check the fingerprints match in browser and in terminal.

### Reconnect to a code-server session
When running the script, it creates a local file called reconnect_info in the installation directory, which contains all information regarding the used ports, the remote ip address, the command for the SSH tunnel and the URL for the browser. This information should be sufficient to reconnect to a code-server session if connection was lost.

## Cleanup after the job
Please note that when you finish working with the code-server, you need to terminate on the local machine by pressing the enter key so the script can terminate the job on the cluster as well as stop the SSH tunnel from your local machine.


## Main author
* Samuel Fux

## Contributions
* Andreas Lugmayr
* James Moore
