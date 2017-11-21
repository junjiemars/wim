# minimal .bashrc, can be on Docker or EC2

export HOME=${HOME%/}

case ".$PS1" in
	.|.\\s*|.[\\*|.\\h:*)
		PS1="\u@\h:\w\$ "
		;;
	*)
		;;
esac

#PREFIX=/opt

# fix set locale failed
# sudo localedef -i en_US -f UTF-8 en_US.UTF-8

# prologue
if [ -z "$LANG" ]; then 
	export LANG=en_US.UTF-8
fi


# vars, paths, and aliases
test -f $HOME/.bash_vars && . $HOME/.bash_vars

test -f $HOME/.bash_paths && . $HOME/.bash_paths

test -f $HOME/.bash_aliases && . $HOME/.bash_aliases 

# epilogue
#---------- 


#TMOUT=3000 # seconds
#readonly TMOUT
#export TMOUT

