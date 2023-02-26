# Configuration environments that everyone should have
if ( $?USER == 0 || $?prompt == 0 ) exit

set autoexpand
set filec

bindkey -k up history-search-backward
bindkey -k down history-search-forward
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# bindkey -k right forward-word
# bindkey -k left backward-word

### group-write by default
umask 002

stty werase ^w
stty erase ^h
stty erase '^?'


# source /remote/sge/default/snps/common/settings.csh
### fix up $DISPLAY for qsh jobs
if ($?DISPLAY) then
    echo $DISPLAY | grep '^:' >& /dev/null
    if (! $status) then
            setenv DISPLAY `hostname`$DISPLAY
    endif
endif




 complete git 'n/checkout/`git branch`/' 'n/commit/(-m)/' 'p/1/(fetch status     clone log tag push checkout branch add commit stash)/'
 complete checkout 'p/1/`git branch`/'
 complete p4  'p/1/(client status filelog submit sync add delete )/'
