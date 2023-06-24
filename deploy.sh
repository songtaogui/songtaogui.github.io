#!/usr/bin/env bash
# Songtao Gui

# set -o xtrace
# set -o errexit
set -o nounset
set -o pipefail

# >>>>>>>>>>>>>>>>>>>>>>>> Load Common functions >>>>>>>>>>>>>>>>>>>>>>>>
export quiet=FALSE
export verbose=TRUE
source ~/.gst_config/path.cfg
source $EASYBASH/lib/common.sh
if [ $? -ne 0 ];then 
    echo -e "\033[31m\033[7m[ERROR]\033[0m --> Cannot load common functions from easybash lib: $EASYBASH" >&2
    exit 1;
fi
# gst_rcd "Common functions loaded"
# <<<<<<<<<<<<<<<<<<<<<<<< Common functions <<<<<<<<<<<<<<<<<<<<<<<<

usage=$(
cat <<EOF
------------------------------------------------------------
Deploy my blog on github:
1. find all markdown files that had "encrypt = true", and encrypt the related html file;
2. cd to "__site" dir, "git add .", "git commit" and "git push"
------------------------------------------------------------
Dependence: staticrypt
------------------------------------------------------------
USAGE:
    bash $(basename $0) [OPTIONS]

OPTIONS: ([R]:required  [O]:optional)
    -h, --help                          show help and exit.
    -b, --builder                       deploy the builder instead of the blog site.
    -f, --force                         force git push 
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

check_sftw_path staticrypt

# >>>>>>>>>>>>>>>>>>>>>>>> Parse Options >>>>>>>>>>>>>>>>>>>>>>>>
# Set Default Opt
export template="_layout/staticrypt_template.html"
export commit=$(date +'%y-%m-%d %H:%M')
export builder=FALSE
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
        -b|--builder)
            builder=TRUE
            shift 1
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

if [ "$builder" == "TRUE" ];then
    gst_log "Deploying to blogbuilder $(git branch -vv)..."
    if [[ $dryrun != "TRUE" ]];then
        git add . &&\
        git commit -m "$commit" &&\
        if [ "$force" == "TRUE" ];then
            git push -u origin master -f
        else
            git push origin master
        fi
    else
        gst_warn "Dryrun commands:
        -------------------------------
            git add . &&\\
            git commit -m \"$commit\" &&\\
            git push origin master
        -------------------------------
        "
    fi
else
gst_log "Deploying to my blog site $(git branch -vv)..."
gst_rcd "Check ref.bib and format ..."
# check if the ref.bib has been updated with md5
if ! md5sum -c _assets/citedb/ref.bib.md5 1>/dev/null 2>&1; then
    gst_rcd "ref.bib has been updated, re-format it ..."
    # remove the file and abstract track from bib
    mv _assets/citedb/ref.bib _assets/citedb/ref.bib.bak &&\
    perl -pe '
        s/^\s*file = \{.*\},\s*$//g;
        s/^\s*abstract = \{.*\},\s*$//g;
    ' _assets/citedb/ref.bib.bak |\
    perl -lane '
        # keep only intact records:
        # records with title, author|editor, year, journal|publisher
        if(/^@/){
            $cur_key = $F[0];
            $cur_key =~ s/@.*?\{(.*),$/$1/;
            @cur_record = ();
            $in_record = 1;
            $abstract = 0;
            $valid_score = 0;
            push @cur_record, $_;
        }elsif($in_record){
            # skip abstract record
            if(/^\s*abstract = /){
                $abstract = 1;
            }elsif(/^\s*\}/ and $abstract == 1){
                $abstract = 0;
                next;
            }
            push @cur_record, $_ if $abstract == 0;
            if(/^}/){
                $in_record = 0;
                foreach $line (@cur_record){
                    if( $line =~ /^\s*title = / or
                        $line =~ /^\s*(author|editor) = / or
                        $line =~ /^\s*year/ or
                        $line =~ /^\s*(journal|publisher) = /)
                    {
                        $valid_score ++;
                    }
                }
                if($valid_score >= 4){
                    print join("\n", @cur_record);
                }else{
                    print STDERR "\033[35m[WARNING]\033[0m -->","Skip invalid record:$cur_key";
                }
            }
        }
    ' > _assets/citedb/ref.bib &&\
    md5sum _assets/citedb/ref.bib > _assets/citedb/ref.bib.md5
    if [ $? -ne 0 ];then gst_err "md5sum ref.bib failed: Non-zero exit"; exit 1;fi
else
    gst_rcd "ref.bib has not been updated, skip re-format ..."
fi

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
            PSWD=$FRANKLINPSWD1
        elif [[ "$encode" == "encrypt = 2" ]];then
            PSWD=$FRANKLINPSWD2
        elif [[ "$encode" == "encrypt = 3" ]];then
            PSWD=$FRANKLINPSWD3
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
            gst_warn "skip $htmlfile"
        fi
        # encrypt it
        if [[ $CRPYT == "TRUE" ]];then
            gst_rcd "Encrypt $htmlfile ..."
            staticrypt --password $PSWD \
                --template $template \
                --short \
                --template-remember "Remember me (30 days)"\
                --template-button "DECRYPT" \
                --template-color-primary "#81B8F7" \
                --template-color-secondary "#DAEFF8" \
                --template-error "Bad password!" \
                --template-placeholder "Password" \
                --template-title "Show me what you got" \
                --remember 30 \
                $htmlfile &&\
            mv -f encrypted/$(basename $htmlfile) $htmlfile &&\
            rm -rf encrypted
            if [ $? -ne 0 ];then gst_err "staticrypt $htmlfile failed: Non-zero exit"; exit 1;fi
        fi
    fi
done
if [ $? -ne 0 ];then gst_err "Presteps failed: Non-zero exit"; exit 1;fi

gst_log "Deploy on github with commit [ $commit ] ..."


if [[ $dryrun != "TRUE" ]];then
    cd __site || exit 1
    git add . &&\
    git commit -m "$commit" &&\
    if [ "$force" == "TRUE" ];then
        git push -u origin master -f
    else
        git push origin master
    fi
else
   gst_warn "Dryrun commands:
-------------------------------
    cd __site &&\\
    git add . &&\\
    git commit -m \"$commit\" &&\\
    git push origin master
-------------------------------
   "
fi # end of if dryrun
fi # end of if builder
if [ $? -ne 0 ];then gst_err "Deploy failed: Non-zero exit"; exit 1;fi

gst_log "All Done !"
