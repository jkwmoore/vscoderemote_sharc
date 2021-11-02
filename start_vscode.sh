#!/bin/bash

###############################################################################
#                                                                             #
#  Script to run on a local computer to start a code-server on Euler and      #
#  connect it with a local browser to it                                      #
#                                                                             #
#  Main author    : Samuel Fux                                                #
#  Contributions  : Andreas Lugmayr                                           #
#  Date           : October 2021                                              #
#  Location       : ETH Zurich                                                #
#  Version        : 0.1                                                       #
#  Change history :                                                           #
#                                                                             #
#  28.10.2021    Initial version of the script based on Jupyter script        #
#                                                                             #
###############################################################################

###############################################################################
# Configuration options, initalising variables and setting default values     #
###############################################################################

# Version
VSC_VERSION="0.1"

# Script directory
VSC_SCRIPTDIR=$(pwd)

# hostname of the cluster to connect to
VSC_HOSTNAME="euler.ethz.ch"

# order for initializing configuration options
# 1. Defaults values set inside this script
# 2. Command line options overwrite defaults
# 3. Config file options  overwrite command line options

# Configuration file default    : $HOME/.vsc_config
VSC_CONFIG_FILE="$HOME/.vsc_config"

# Username default              : no default
VSC_USERNAME=""

# Number of CPU cores default   : 1 CPU core
VSC_NUM_CPU=1

# Runtime limit default         : 1:00 hour
VSC_RUN_TIME="01:00"

# Memory default                : 1024 MB per core
VSC_MEM_PER_CPU_CORE=1024

# Number of GPUs default        : 0 GPUs
VSC_NUM_GPU=0

# Waiting interval default      : 60 seconds
VSC_WAITING_INTERVAL=60

# SSH key location default      : no default
VSC_SSH_KEY_PATH=""

###############################################################################
# Usage instructions                                                          #
###############################################################################

function display_help {
cat <<-EOF
$0: Script to start a VSCode on Euler from a local computer

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

        ./start_vscode.sh -c $HOME/.vsc_config

Format of configuration file:

VSC_USERNAME=""             # ETH username for SSH connection to Euler
VSC_NUM_CPU=1               # Number of CPU cores to be used on the cluster
VSC_NUM_GPU=0               # Number of GPUs to be used on the cluster
VSC_RUN_TIME="01:00"        # Run time limit for the code-server in hours and minutes HH:MM
VSC_MEM_PER_CPU_CORE=1024   # Memory limit in MB per core
VSC_WAITING_INTERVAL=60     # Time interval to check if the job on the cluster already started
VSC_SSH_KEY_PATH=""         # Path to SSH key with non-standard name

EOF
exit 1
}

###############################################################################
# Parse configuration options                                                 #
###############################################################################

while [[ $# -gt 0 ]]
do
        case $1 in
                -h|--help)
                display_help
                ;;
                -v|--version)
                echo -e "start_vscode.sh version: $VSC_VERSION\n"
                exit
                ;;
                -u|--username)
                VSC_USERNAME=$2
                shift
                shift
                ;;
                -n|--numcores)
                VSC_NUM_CPU=$2
                shift
                shift
                ;;
                -W|--runtime)
                VSC_RUN_TIME=$2
                shift
                shift
                ;;
                -m|--memory)
                VSC_MEM_PER_CPU_CORE=$2
                shift
                shift
                ;;
                -c|--config)
                VSC_CONFIG_FILE=$2
                shift
                shift
                ;;
                -g|--numgpu)
                VSC_NUM_GPU=$2
                shift
                shift
                ;;
                -i|--interval)
                VSC_WAITING_INTERVAL=$2
                shift
                shift
                ;;
                -k|--key)
                VSC_SSH_KEY_PATH=$2
                shift
                shift
                ;;
                *)
                echo -e "Warning: ignoring unknown option $1 \n"
                shift
                ;;
        esac
done

###############################################################################
# Check configuration options                                                 #
###############################################################################

# check if user has a configuration file and source it to initialize options
if [ -f "$VSC_CONFIG_FILE" ]; then
        echo -e "Found configuration file $VSC_CONFIG_FILE"
        echo -e "Initializing configuration from file ${VSC_CONFIG_FILE}:"
        cat "$VSC_CONFIG_FILE"
        source "$VSC_CONFIG_FILE"
fi

# check that VSC_USERNAME is not an empty string
if [ -z "$VSC_USERNAME" ]
then
        echo -e "Error: No ETH username is specified, terminating script\n"
        display_help
else
        echo -e "ETH username: $VSC_USERNAME"
fi

# check number of CPU cores

# check if VSC_NUM_CPU an integer
if ! [[ "$VSC_NUM_CPU" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $VSC_NUM_CPU -> Incorrect format. Please specify number of CPU cores as an integer and try again\n"
        display_help
fi

# check if VSC_NUM_CPU is <= 128
if [ "$VSC_NUM_CPU" -gt "128" ]; then
        echo -e "Error: $VSC_NUM_CPU -> Larger than 128. No distributed memory supported, therefore the number of CPU cores needs to be smaller or equal to 128\n"
        display_help
fi

if [ "$VSC_NUM_CPU" -gt "0" ]; then
        echo -e "Requesting $VSC_NUM_CPU CPU cores for running the code-server"
fi

# check number of GPUs

# check if VSC_NUM_GPU an integer
if ! [[ "$VSC_NUM_GPU" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $VSC_NUM_GPU -> Incorrect format. Please specify the number of GPU as an integer and try again\n"
        display_help
fi

# check if VSC_NUM_GPU is <= 8
if [ "$VSC_NUM_GPU" -gt "8" ]; then
        echo -e "Error: No distributed memory supported, therefore number of GPUs needs to be smaller or equal to 8\n"
        display_help
fi

if [ "$VSC_NUM_GPU" -gt "0" ]; then
        echo -e "Requesting $VSC_NUM_GPU GPUs for running the jupyter notebook"
        VSC_SNUM_GPU="-R \"rusage[ngpus_excl_p=$VSC_NUM_GPU]\""
else
        VSC_SNUM_GPU=""
fi

if [ ! "$VSC_NUM_CPU" -gt "0" -a ! "$VSC_NUM_GPU" -gt "0" ]; then
        echo -e "Error: No CPU and no GPU resources requested, terminating script"
        display_help
fi

# check if VSC_RUN_TIME is provided in HH:MM format
if ! [[ "$VSC_RUN_TIME" =~ ^[0-9][0-9]:[0-9][0-9]$ ]]; then
        echo -e "Error: $VSC_RUN_TIME -> Incorrect format. Please specify runtime limit in the format HH:MM and try again\n"
        display_help
else
    echo -e "Run time limit set to $VSC_RUN_TIME"
fi

# check if VSC_MEM_PER_CPU_CORE is an integer
if ! [[ "$VSC_MEM_PER_CPU_CORE" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $VSC_MEM_PER_CPU_CORE -> Memory limit must be an integer, please try again\n"
        display_help
else
    echo -e "Memory per core set to $VSC_MEM_PER_CPU_CORE MB"
fi

# check if VSC_WAITING_INTERVAL is an integer
if ! [[ "$VSC_WAITING_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $VSC_WAITING_INTERVAL -> Waiting time interval [seconds] must be an integer, please try again\n"
        display_help
else
    echo -e "Setting waiting time interval for checking the start of the job to $VSC_WAITING_INTERVAL seconds"
fi

# set modules
VSC_MODULE_COMMAND="gcc/6.3.0 code-server/3.12.0 eth_proxy"

# check if VSC_SSH_KEY_PATH is empty or contains a valid path
if [ -z "$VSC_SSH_KEY_PATH" ]; then
        VSC_SKPATH=""
else
        VSC_SKPATH="-i $VSC_SSH_KEY_PATH"
        echo -e "Using SSH key $VSC_SSH_KEY_PATH"
fi

# put together string for SSH options
VSC_SSH_OPT="$VSC_SKPATH $VSC_USERNAME@$VSC_HOSTNAME"

###############################################################################
# Check for leftover files                                                    #
###############################################################################

# check if some old files are left from a previous session and delete them

# check for reconnect_info in the current directory on the local computer
echo -e "Checking for left over files from previous sessions"
if [ -f $VSC_SCRIPTDIR/reconnect_info ]; then
        echo -e "Found old reconnect_info file, deleting it ..."
        rm $VSC_SCRIPTDIR/reconnect_info
fi

# check for log files from a previous session in the home directory of the cluster
ssh -T $VSC_SSH_OPT <<ENDSSH
if [ -f /cluster/home/$VSC_USERNAME/vscip ]; then
        echo -e "Found old vscip file, deleting it ..."
        rm /cluster/home/$VSC_USERNAME/vscip
fi
ENDSSH

###############################################################################
# Start code-server on the cluster                                            #
###############################################################################

# run the code-server job on Euler and save the ip of the compute node in the file vscip in the home directory of the user on Euler
echo -e "Connecting to $VSC_HOSTNAME to start jupyter notebook in a batch job"
# FIXME: save jobid in a variable, that the script can kill the batch job at the end
ssh $VSC_SSH_OPT bsub -n $VSC_NUM_CPU -W $VSC_RUN_TIME -R "rusage[mem=$VSC_MEM_PER_CPU_CORE]" $VSC_SNUM_GPU  <<ENDBSUB
module load $VSC_MODULE_COMMAND
export XDG_RUNTIME_DIR="\$HOME/vsc_runtime"
VSC_IP_REMOTE="\$(hostname -i)"
echo "Remote IP:\$VSC_IP_REMOTE" >> /cluster/home/$VSC_USERNAME/vscip
code-server --bind-addr=\${VSC_IP_REMOTE}:8899
ENDBSUB

# wait until batch job has started, poll every $VSC_WAITING_INTERVAL seconds to check if /cluster/home/$VSC_USERNAME/vscip exists
# once the file exists and is not empty the batch job has started
ssh $VSC_SSH_OPT <<ENDSSH
while ! [ -e /cluster/home/$VSC_USERNAME/vscip -a -s /cluster/home/$VSC_USERNAME/vscip ]; do
        echo 'Waiting for code-server to start, sleep for $VSC_WAITING_INTERVAL sec'
        sleep $VSC_WAITING_INTERVAL
done
ENDSSH

# give the code-server a few seconds to start
sleep 7

# get remote ip, port and token from files stored on Euler
echo -e "Receiving ip, port and token from jupyter notebook"
VSC_REMOTE_IP=$(ssh $VSC_SSH_OPT "cat /cluster/home/$VSC_USERNAME/vscip | grep -m1 'Remote IP' | cut -d ':' -f 2")
VSC_REMOTE_PORT=8899

# check if the IP, the port and the token are defined
if  [[ "$VSC_REMOTE_IP" == "" ]]; then
cat <<EOF
Error: remote ip is not defined. Terminating script.
* Please check login to the cluster and check with bjobs if the batch job on the cluster is running and terminate it with bkill.
EOF
exit 1
fi

# print information about IP, port and token
echo -e "Remote IP address: $VSC_REMOTE_IP"
echo -e "Remote port: $VSC_REMOTE_PORT"

# get a free port on local computer
echo -e "Determining free port on local computer"
#VSC_LOCAL_PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()')
# FIXME: check if there is a solution that does not require python (as some Windows computers don't have a usable Python installed by default)
# if python is not available, one could use
VSC_LOCAL_PORT=$((3 * 2**14 + RANDOM % 2**14))
# as a replacement. No guarantee that the port is unused, but so far best non-Python solution

echo -e "Using local port: $VSC_LOCAL_PORT"

# write reconnect_info file
cat <<EOF > $VSC_SCRIPTDIR/reconnect_info
Restart file
Remote IP address : $VSC_REMOTE_IP
Remote port       : $VSC_REMOTE_PORT
Local port        : $VSC_LOCAL_PORT
SSH tunnel        : ssh $VSC_SSH_OPT -L $VSC_LOCAL_PORT:$VSC_REMOTE_IP:$VSC_REMOTE_PORT -N &
URL               : http://localhost:$VSC_LOCAL_PORT
EOF

# setup SSH tunnel from local computer to compute node via login node
# FIXME: check if the tunnel can be managed via this script (opening, closing) by using a control socket from SSH
echo -e "Setting up SSH tunnel for connecting the browser to the jupyter notebook"
ssh $VSC_SSH_OPT -L $VSC_LOCAL_PORT:$VSC_REMOTE_IP:$VSC_REMOTE_PORT -N &

# SSH tunnel is started in the background, pause 5 seconds to make sure
# it is established before starting the browser
sleep 5

# save url in variable
VSC_URL=http://localhost:$VSC_LOCAL_PORT
echo -e "Starting browser and connecting it to jupyter notebook"
echo -e "Connecting to url $VSc_URL"

# start local browser if possible
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        xdg-open $VSC_URL
elif [[ "$OSTYPE" == "darwin"* ]]; then
        open $VSC_URL
elif [[ "$OSTYPE" == "msys" ]]; then # Git Bash on Windows 10
        start $VSC_URL
else
        echo -e "Your operating system does not allow to start the browser automatically."
        echo -e "Please open $VSC_URL in your browser."
fi
