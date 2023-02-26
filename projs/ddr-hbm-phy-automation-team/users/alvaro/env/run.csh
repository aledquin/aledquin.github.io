#!/usr/bin/tcsh -f

set ROOTDIR = `dirname $0`
set instance = `date +"%F-%H-%M"`

set CAD_REP_PATH = "/remote/cad-rep/etc/.cshrc"
set RC_FILE = "$HOME/.cshrc"
set RC_LINK = `readlink -f $RC_FILE`
set RC_USER = ".cshrc.user"
set ENV_DIR = "$HOME/env"
set AL_USER = ".alias.$USER"

# RC Files
if ($RC_LINK != $CAD_REP_PATH) then  
    mv $RC_FILE $RC_FILE.$instance
    ln -sf $CAD_REP_PATH $RC_FILE
endif

if ( -f $RC_FILE.$USER && `diff $ROOTDIR/$RC_USER $RC_FILE.$USER | wc -l`) then  
    mv $RC_FILE.$USER $RC_FILE.$USER.$instance
endif
cp -f $ROOTDIR/$RC_USER $RC_FILE.$USER


# ENV directory
if ( -d $ENV_DIR ) then
    mv $ENV_DIR $ENV_DIR.$instance
    if (-f $RC_FILE.$instance) mv $RC_FILE.$instance $ENV_DIR.$instance/$RC_FILE
endif
cp -rf $ROOTDIR $ENV_DIR


# Alias 
if (-f $ENV_DIR.$instance/$AL_USER) then 
    cp -f $ENV_DIR.$instance/$AL_USER $ENV_DIR/$AL_USER
else if (-f $HOME/$AL_USER) then
    mv -f $HOME/$AL_USER $ENV_DIR/$AL_USER
else 
    touch $ENV_DIR/$AL_USER
endif


# Permissions
chmod 775 -R $ENV_DIR
rm -f $ENV_DIR/run.csh


# Report
diff -r $ENV_DIR.$instance/ $ENV_DIR/ > $ENV_DIR/report-$instance.log
echo $ENV_DIR/report-$instance.log
echo $instance


#Run new ENV
source $RC_FILE
