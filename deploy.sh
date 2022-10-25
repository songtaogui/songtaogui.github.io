#!/usr/bin/env bash
# Songtao Gui

# set -o xtrace
# set -o errexit
set -o nounset
set -o pipefail

# >>>>>>>>>>>>>>>>>>>>>>>> Load Common functions >>>>>>>>>>>>>>>>>>>>>>>>
export quiet=FALSE
export verbose=TRUE
source $EASYBASH/lib/common.sh
if [ $? -ne 0 ];then 
    echo -e "\033[31m\033[7m[ERROR]\033[0m --> Cannot load common functions from easybash lib: $EASYBASH" >&2
    exit 1;
fi
gst_rcd "Common functions loaded"
# <<<<<<<<<<<<<<<<<<<<<<<< Common functions <<<<<<<<<<<<<<<<<<<<<<<<

usage=$(
cat <<EOF
------------------------------------------------------------
Deploy my blog on github:
1. find all markdown files that had "encrypt = true", and encrypt the related html file;
2. cd to "__site" dir, "git add .", "git commit" and "git push"
------------------------------------------------------------
Dependence:
------------------------------------------------------------
USAGE:
    bash $(basename $0) [OPTIONS]

OPTIONS: ([R]:required  [O]:optional)
    -h, --help                          show help and exit.
    -m, --commit  <str>                 github commit info, default: 'date'
    -d, --dryrun                        skip the github deploy step, just output the cmd
    --quiet                             keep quiet, only output fatal errors
    --verbose                           be verbose, output detailed logs
------------------------------------------------------------
Author: Songtao Gui
E-mail: songtaogui@sina.com

EOF
)
# if [[ $# -eq 0 ]]; then
    # echo "$usage" >&2
    # exit 1
# fi

# >>>>>>>>>>>>>>>>>>>>>>>> Parse Options >>>>>>>>>>>>>>>>>>>>>>>>
# Set Default Opt
export commit=$(date +'%y-%m-%d %H:%M')
export force=FALSE
export dryrun=FALSE
# parse args
UNKOWN_ARGS=()
while [[ $# > 0 ]]; do
    case "$1" in
        -h|--help)
            echo "$usage" >&2
            exit 1
        ;;
        -m|--commit)
            commit=$2
            shift 2
        ;;
        -f|--force)
            force=TRUE
            shift 1
        ;;
        -d|--dryrun)
            dryrun=TRUE
            shift 1
        ;;
        --quiet)
            quiet=TRUE
            shift 1
        ;;
        --verbose)
            verbose=TRUE
            shift 1
        ;;
        *) # unknown flag/switch
            UNKOWN_ARGS+=("$1")
            shift
        ;;
    esac
done
if [ "${#UNKOWN_ARGS[@]}" -gt 0 ];then
    echo "[ERROR] --> Wrong options: \"${UNKOWN_ARGS[@]}\"" >&2
    exit 1
fi
unset UNKOWN_ARGS # restore UNKOWN_ARGS params
# <<<<<<<<<<<<<<<<<<<<<<<< Parse Options <<<<<<<<<<<<<<<<<<<<<<<<


gst_log "Encrypting private files ..."

find . -name "*.md" | grep -v -P "^\.\/[_\.]" | while read mdfile
do
    # check if name with space
    if [[ "${mdfile}" == *" "* ]]; then
        gst_err "file [ $mdfile ] should NOT contain whitespace in the name !"
        exit 1
    fi
    # check if has encrypt code
    encode=$(grep -o -P "^encrypt = ([123])" $mdfile)
    if [[ -n "${encode}" ]]; then
        PSWD=""
        CRPYT="FALSE"
        if [[ "$encode" == "encrypt = 1" ]];then
            PSWD=$PERSONALPSWD
        elif [[ "$encode" == "encrypt = 2" ]];then
            PSWD=$WORKPSWD
        elif [[ "$encode" == "encrypt = 3" ]];then
            PSWD=$WORKPSWD2
        fi
        if [[ -z "${PSWD}" ]]; then
            gst_err "no password detected! Please check the env!"
            exit 1
        fi
        # get the html file:
        htmlfile=$(echo "$mdfile" | perl -pe '
            s/^\.\//\.\/__site\//;
            if(/index.md$/){
                s/\.md$/\.html/;
            }else{
                s/\.md$/\/index.html/;
            }
            ')
        check_files_exists $htmlfile
        # check if htmlfile is already encrypted
        head $htmlfile | grep "staticrypt" 1>/dev/null 2>&1
        if [ $? -ne 0 ];then
            # un-encrypted
            CRPYT="TRUE"
        else
            # already encrypted
            if [[ $force == "TRUE" ]];then
                CRPYT="TRUE"
                gst_warn "force re-encrypt $htmlfile ..."
            else
                gst_warn "skip $htmlfile"
            fi
        fi
        # encrypt it
        if [[ $CRPYT == "TRUE" ]];then
            gst_rcd "Encrypt $htmlfile ..."
            staticrypt $htmlfile $PSWD \
                -o $htmlfile.new \
                --remember-label "Remember me in the next 30 days" -r 30 \
                &&\
            mv $htmlfile.new $htmlfile
            if [ $? -ne 0 ];then gst_err "staticrypt $htmlfile failed: Non-zero exit"; exit 1;fi
        fi
    fi
done

gst_log "Deploy on github with commit [ $commit ] ..."

if [[ $dryrun != "TRUE" ]];then
    cd __site || exit 1
    git add . &&\
    git commit -m "$commit" &&\
    git push origin master
else
   gst_warn "Dryrun commands:
-------------------------------
    cd __site &&\\
    git add . &&\\
    git commit -m \"$commit\" &&\\
    git push origin master
-------------------------------
   "
fi

if [ $? -ne 0 ];then gst_err "Deploy failed: Non-zero exit"; exit 1;fi

gst_log "All Done !"
