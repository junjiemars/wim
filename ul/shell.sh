#!/usr/bin/env bash
#------------------------------------------------
# target: shell env setup script	
# author: junjiemars@gmail.com
#------------------------------------------------

HOME="${HOME%/}"
PLATFORM="`uname -s 2>/dev/null`"
SH="`basename $SHELL`"
SH_ENV="https://raw.githubusercontent.com/junjiemars/kit/master/ul/shell.sh"

save_as() {
  local f="$1"
	local ori="${f}.ori"
  local pre="${f}.pre"

  if [ -f ${f} ]; then
		if [ -f ${ori} ]; then
      cp $f $pre
    else
      cp $f $ori
    fi
  fi
}

on_windows_nt() {
 case "$PLATFORM" in
   MSYS_NT*|MINGW*) return 0 ;;
   *) return 1 ;;
 esac
}

on_darwin() {
  case "$PLATFORM" in
    Darwin) return 0 ;;
    *) return 1 ;;
  esac
}

on_linux() {
  case "$PLATFORM" in
    Linux) return 0 ;;
    *) return 1 ;;
  esac
}

posix_path() { 
  local p="$@"
  local v=
  if [[ $p =~ ^[a-zA-Z]:[\/\\].*$ ]]; then
    if [ "abc" = `echo "ABC" | sed -e 's#\([A-Z]*\)#\L\1#g'` ]; then
      v=$(echo "\\$p" | sed -e 's#^\\\([a-zA-Z]\):[\/\\]#\\\L\1\\#')
    else
      local car="`echo $p | cut -d':' -f1`"
      local cdr="`echo $p | cut -d':' -f2`"
      if [ "$p" = "${car}:${cdr}" ]; then
        v=$(echo $car | tr [:upper:] [:lower:])
        v=$(echo "\\${v}${cdr}" | sed -e 's#^\\\([a-zA-Z]\):[\/\\]#\\\1\\#')
      else
        v=$(echo "\\$p" | sed -e 's#^\\\([a-zA-Z]\):[\/\\]#\\\1\\#')
      fi
    fi;
  fi
  echo "$v" | sed -e 's#\\#\/#g'
}

sort_path() {
  # Windows: let MSYS_NT and user defined commands first
	local awk='/bin/awk'
	local tr='/usr/bin/tr'
	local grep='/usr/bin/grep'
	local paths="$@"
	local opt_p="`/usr/bin/dirname $OPT_RUN`"
	local win_p="^/c/"
  local opt=
  local ori=
  local win=
  local sorted=

	opt="`echo -n "$paths" | $tr ':' '\n' | $grep "$opt_p" | $tr '\n' ':' `"
  
  ori="`echo -n "$paths" | $tr ':' '\n' | $grep -v "$opt_p" | $grep -v "$win_p" | $tr '\n' ':' `"
  
  win="`echo -n "$paths" | $tr ':' '\n' | $grep "$win_p" | $tr '\n' ':' `"
  
  sorted="`echo -n "${ori}${opt:+$opt }${win}" | $awk '!xxx[$0]++' | sed -e 's#:$##' -e 's#:\  *\/#:\/#g' `"
  
  echo -n "${sorted}" 
}

get_sed_opt_i() {
  if on_darwin; then
    echo "-i $1"
  else
    echo "-i$1"
  fi
}

delete_tail_lines() {
	local h="$1"
  local lines="$2"
	local f="$3"
	local sed_opt_i="`get_sed_opt_i .pre`"

  [ -f "$f" ] || return 1

  local line_no=`grep -m1 -n "^${h}" $f | cut -d':' -f1`
  [[ $line_no =~ ^[0-9]+$ ]] || return 1

  if [ 0 -lt $line_no ]; then
    if [ "yes" = "$lines" ]; then
      sed $sed_opt_i -e "$line_no,\$d" "$f"
    else  
      sed $sed_opt_i -e "${line_no}d" "$f"
    fi
  fi
}

gen_dot_shell_profile() {
	local profile="$HOME/.bash_profile"
	if [ "zsh" = "$SH" ]; then
		profile="$HOME/.zprofile"
	fi
	save_as "$profile"
	echo -n "+ generate $profile ... "
  cat << END > "$profile"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $profile
# target: call .${SH}rc
# author: junjiemars@gmail.com
# generated by: 
#   $SH <($SH_ENV)
`if [ -f "${profile}.ori" ]; then
  echo "# origin backup: ${profile}.ori"
fi`
#------------------------------------------------

test -r \$HOME/.${SH}rc && . \$HOME/.${SH}rc

# eof
END
	if [ 0 -eq $? ]; then
		echo "yes"
	else
		echo "no"
	fi
}

gen_dot_shell_logout() {
	local logout="$HOME/.${SH}_logout"
	if [ "zsh" = "$SH" ]; then
		logout="$HOME/.zlogout"
	fi
	save_as "$logout"
	echo -n "+ generate $logout ... "
  cat << END > "$logout"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $logout
# target: be called when logout
# author: junjiemars@gmail.com
# generated by: 
#   $SH <($SH_ENV)
`if [ -f "${logout}.ori" ]; then
  echo "# origin backup: ${logout}.ori"
fi`
#------------------------------------------------

# `basename ${logout}`: executed by ${SH}(1) when login shell exits.
# when leaving the console clear the screen to increase privacy

if [ "\$SHLVL" = 1 ]; then
  [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

# eof
END
	if [ 0 -eq $? ]; then
		echo "yes"
	else
		echo "no"
	fi
}

gen_dot_shell_rc() {
	local rc="$HOME/.${SH}rc"
	save_as "$rc"
	if [ ! -f "$rc" ]; then
		echo -n "+ generate $rc ... "
  	cat << END > "$rc"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $rc
# target: .${SH}rc default
# author: junjiemars@gmail.com
# generated by: 
#   $SH <($SH_ENV)
`if [ -f "${rc}.ori" ]; then
  echo "# origin backup: ${rc}.ori"
fi`
#------------------------------------------------

END
	else
		echo -n "+ append $rc ... "
		delete_tail_lines "# call .${SH}_init" "yes" "$HOME/.${SH}rc" 
	fi # end of ! -f "$rc"

	echo -e "# call .${SH}_init" >> "$HOME/.${SH}rc"
	cat << END >> "$HOME/.${SH}rc"
`if on_darwin -a test -d "/opt/local/bin"; then
	echo "# PATH=\"/opt/local/bin\\${PATH:+:\\${PATH}}\""
fi`
test -f \$HOME/.${SH}_init && . \$HOME/.${SH}_init
export PATH
`if on_linux; then
		if [ -n "$LD_LIBRARY_PATH" ]; then
  		echo "export LD_LIBRARY_PATH"
		else
			echo "# export LD_LIBRARY_PATH"
		fi
elif on_darwin; then
	if [ -n "$DYLD_LIBRARY_PATH" ]; then
		echo "export DYLD_LIBRARY_PATH"
	else
		echo "# export DYLD_LIBRARY_PATH"
	fi
fi`

# eof
END

	if [ 0 -eq $? ]; then
		echo "yes"
	else
		echo "no"
	fi
}

gen_dot_shell_init() {
	local init="$HOME/.${SH}_init"
	save_as "$init"
	echo -n "+ generate $init ... "
  cat << END > "$init"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $init
# target: initialize .zsh_* scripts
# author: junjiemars@gmail.com
# generated by: 
#   $SH <($SH_ENV)
`if [ -f "${init}.ori" ]; then
  echo "# origin backup: ${init}.ori"
fi`
#------------------------------------------------

PLATFORM="\`uname -s 2>/dev/null\`"
MACHINE="\`uname -m 2>/dev/null\`"

inside_docker_p() {
  [ ".\$INSIDE_DOCKER" = ".1" ] && return 0
  [ -f /proc/1/cgroup ] || return 1
  if \`cat /proc/1/cgroup | grep '/docker/' >/dev/null\`; then
		export INSIDE_DOCKER=1
	else
		export INSIDE_DOCKER=0
	fi 
}

inside_emacs_p() {
  test -n "\$INSIDE_EMACS"
}

get_sed_opt_i() {
`
	if on_darwin; then
  	echo -e "  echo \\"-i \\$1\\""
	else
  	echo -e "  echo \\"-i\\$1\\""
	fi
`
}

`
declare -f delete_tail_lines
`

pretty_ps1() {
  local o="\$PS1"
`if [ "zsh" = "$SH" ]; then
		echo "  local ps1='%n@%m: %1~ %'"
	else
		echo "  local ps1='\u@\h: \W \\$'"
fi`

	if [ -z "\$o" ]; then
		echo "\$ps1"
	elif [ "\$o" = "\$ps1" ]; then
		echo "\$o"
	elif \`inside_emacs_p\`; then	
		echo "\$ps1"
  elif [[ \$o =~ ^\\\(h|s\\\).*$ ]]; then
    echo "\$ps1"
  elif [[ \$o =~ ^\\\\\[.*$ ]]; then
		echo "\$ps1"
	elif [[ \$o =~ ^[a-zA-Z0-9%$]+$ ]]; then
		echo "\$ps1" 
  else
    echo "\$o"
  fi
}

pretty_prompt_command() {
  local o="\${PROMPT_COMMAND[@]}"
  local pc1=''

  if test -n "\${o}"; then
    if \`inside_docker_p\` || \`inside_emacs_p\`; then
      echo "\$pc1"
      return
    fi
  fi
  echo "\$o"
}

pretty_term() {
  local o="\$TERM"
  local t="xterm"

  if [ -z "\$o" ]; then
    echo "\$t"
    return
  fi

  if [ "dumb" = "\$o" ]; then
    if \`inside_emacs_p\`; then
      echo "\$o"
    else
      echo "\$t"
    fi
  else
    echo "\$o"
  fi
}

PROMPT_COMMAND="\$(pretty_prompt_command)"
if [ -z "\$PROMPT_COMMAND" ]; then
	unset PROMPT_COMMAND
else
	export PROMPT_COMMAND
fi

PS1="\$(pretty_ps1)"
export PS1="\${PS1% } "

TERM="\$(pretty_term)"
export TERM

# fix set locale failed
# sudo localedef -i en_US -f UTF-8 en_US.UTF-8

# prologue
#----------

`
if on_windows_nt; then
  echo -e "# change code page to unicode"
  echo -e "chcp.com 65001 &>/dev/null"
  echo -e "export LANG=en_US.UTF-8"
else
  echo -e "if test -z \"\\$LANG\"; then"
  echo -e "  export LANG=en_US.UTF-8"
  echo -e "fi"
fi
`

# vars, paths, and aliases
#----------

test -f \$HOME/.${SH}_vars    && . \$HOME/.${SH}_vars
test -f \$HOME/.${SH}_paths   && . \$HOME/.${SH}_paths
test -f \$HOME/.${SH}_aliases && . \$HOME/.${SH}_aliases

# epilogue
#----------

# eof
END
	if [ 0 -eq $? ]; then
		echo "yes"
	else
		echo "no"
	fi
}

gen_dot_shell_aliases() {
	local aliases="$HOME/.${SH}_aliases"
	save_as "$aliases"
	echo -n "+ generate $aliases ... "
  cat << END > "$aliases"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $aliases
# author: junjiemars@gmail.com
# generated by:
#   ($SH_ENV)
`if [ -f "${aliases}.ori" ]; then
  echo "# origin backup: ${aliases}.ori"
fi`
#------------------------------------------------

alias ..1='cd ../'
alias ..2='cd ../../'
alias ..3='cd ../../../'
alias ..4='cd ../../../../'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

exist_p() {
  command -v \${1} &>/dev/null; echo \$?
}

diff_p() {
  diff \${1} \${2} &>/dev/null; echo \$?
}

has_rlwrap=\$(exist_p 'rlwrap')

`
if on_darwin; then
  echo "alias ls='ls -G'"
  echo "alias ll='ls -lh -G'"
  echo "alias l='ls -CF -G'"
  echo "alias tailf='tail -f'"
  echo "alias stat='stat -x'"
else
  echo "alias ls='ls --color=auto'"
  echo "alias ll='ls -lh --color=auto'"
  echo "alias l='ls -CF --color=auto'"
fi
`

alias_racket() {
	if [ 0 -eq \$has_rlwrap ]; then
		local p_racket=\$(exist_p 'racket')
		if [ 0 -eq \$p_racket ]; then
			local v
			IFS='.' read -a v <<< "\`racket -v|sed 's/.*v\([0-9].[0-9]\).*/\1/g'\`"
			if [ 67 -gt \$(( \${v[0]}*10+\${v[1]} )) ]; then
				alias racket='rlwrap racket'
			fi
      unset IFS
		fi
	fi
}

alias_emacs() {
	local p_emacs=\$(exist_p 'emacs')
	if [ 0 -eq \$p_emacs ]; then
		alias emacs='emacs -nw'
	fi
}

alias_vi() {
	local p_vi=\$(exist_p 'vi')
	local p_vim=\$(exist_p 'vim')
	if [ 0 -eq \$p_vi ] && [ 0 -eq \$p_vim ]; then
	  if [ 0 -ne \$(diff_p \`type -p vi\` \`type -p vim\`) ]; then
	    alias vi=vim
	  fi
	fi
}

alias_rlwrap_bin() {
	local bin="\$1"
	local os="\$2"
	local m=

	if [ -n "\$os" ]; then
		case "\$PLATFORM" in
			\$os) m=0 ;;
			*) m=1 ;;
		esac
	else
		m=0
	fi

	if [ 0 -eq \$m -a 0 -eq \$has_rlwrap ]; then
		local p_bin=\$(exist_p "\$bin")
		if [ 0 -eq \$p_bin ]; then
			alias \$(echo "\$bin")="rlwrap \$bin"
		fi
	fi
}

alias_vi
alias_emacs
alias_racket
alias_rlwrap_bin lein
alias_rlwrap_bin sbcl
alias_rlwrap_bin ecl
alias_rlwrap_bin openssl
alias_rlwrap_bin jjs
alias_rlwrap_bin lldb Linux

# eof
END
	if [ 0 -eq $? ]; then
		echo "yes"
	else
		echo "no"
	fi
}

gen_dot_shell_vars() {
	local vars="$HOME/.zsh_vars"
	save_as "$vars"
	echo -n "+ generate $vars ... "
  cat << END > "$vars"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $vars
# author: junjiemars@gmail.com
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${vars}.ori" ]; then
  echo "# origin backup: ${vars}.ori"
fi`
#------------------------------------------------

`
if on_windows_nt; then
  echo "choose_prefix() {"
  echo "  if [ -d \"/d/\" ]; then"
  echo "    [ -d \"/d/opt\" ] || mkdir -p \"/d/opt\""
  echo "    echo \"/d/opt\""
  echo "  else"
  echo "    [ -d \"/c/opt\" ] || mkdir -p \"/c/opt\""
  echo "    echo \"/c/opt\""
  echo "  fi"
	echo "}"
else
	echo "choose_prefix() {"
  echo "  echo \"/opt\""
	echo "}"
fi
`

OPT_RUN="\${OPT_RUN:-\$(choose_prefix)/run}"
OPT_OPEN="\${OPT_OPEN:-\$(choose_prefix)/open}"

[ -d "\${OPT_RUN}" ]  && export OPT_RUN=\${OPT_RUN}
[ -d "\${OPT_OPEN}" ] && export OPT_OPEN=\${OPT_OPEN}

check_java_env() {
`if on_darwin; then
    echo "  local java_home='/usr/libexec/java_home'"
    echo "  if [ -L \"\\${java_home}\" ]; then"
    echo "    JAVA_HOME=\\$(\\${java_home} 2>/dev/null)"
    echo "  fi"
	elif on_linux; then
    echo "  local javac=\\$(type -p javac 2>/dev/null)"
    echo "  if [ -n \"\\${javac}\" ]; then"
    echo "    local java_home=\\$(readlink -f \"\\${javac}\" | sed 's:/bin/javac::')"
    echo "    if [ -n \"\\${java_home}\" -a -z \"\\$JAVA_HOME\" ]; then"
    echo "      JAVA_HOME=\"\\${java_home}\""
    echo "    fi"
    echo "  fi"
  else
    echo "  # nop"
    echo "  :;"
fi
	echo "  if [ -n \"\\$JAVA_HOME\" ]; then"
  echo "    unset JAVA_HOME"
	echo "  fi"
`
}

check_java_env

# declare vars

# eof
END
	if [ 0 -eq $? ]; then
		echo "yes"
	else
		echo "no"
	fi
}

gen_dot_shell_paths() {
	local paths="$HOME/.${SH}_paths"
	save_as "$paths"
	echo -n "+ generate $paths ... "
  cat << END > "$paths"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $paths
# author: junjiemars@gmail.com
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${paths}.ori" ]; then
  echo "# origin backup: ${paths}.ori"
fi`
#------------------------------------------------

append_path() {
	local new="\$1"
	local paths="\${@:2}"
	echo "\${paths:+\$paths:}\$new"
}

uniq_path() {
  local paths="\$@"
	paths=\`echo "\$paths" | tr ':' '\n' | awk '!a[\$0]++'\`
	paths=\`echo "\$paths" | tr '\n' ':' | sed -e 's_:\$__g'\`
  echo "\$paths"
}

`
declare -f posix_path
`

`
if on_windows_nt; then
  declare -f sort_path
fi
`

set_bin_paths() {
  local paths=(
    '/usr/local/bin'
    '/usr/bin'
    '/bin'
    '/usr/sbin'
    '/sbin'
  )
  
  for d in "\${paths[@]}"; do
    if [ -d "\${d}" ]; then
      PATH="\`append_path \${d} \$PATH\`"
    fi
  done
}


set_bin_paths

# chain basis \${OPT_RUN}/{bin,sbin} paths
if [ -n "\${OPT_RUN}" ]; then
	PATH="\`append_path \${OPT_RUN}/bin \${PATH[@]}\`"
	PATH="\`append_path \${OPT_RUN}/sbin \${PATH[@]}\`"
`
  if on_linux; then
	  echo "  LD_LIBRARY_PATH=\"\\$(append_path \\${OPT_RUN}/lib \\${LD_LIBRARY_PATH[@]})\""
	elif on_darwin; then
	  echo "  DYLD_LIBRARY_PATH=\"\\$(append_path \\${OPT_RUN}/lib \\${DYLD_LIBRARY_PATH[@]})\""
  fi
`
fi

# java home
if [ -n "\${JAVA_HOME}" ]; then
`if on_windows_nt; then
	echo "  JAVA_HOME=\\$(posix_path \"\\${JAVA_HOME}\")"
fi`
  PATH="\`append_path \"\${JAVA_HOME}\" \$PATH\`"
  PATH="\`append_path \"\${JAVA_HOME}/bin\" \$PATH\`"
fi

`if on_windows_nt; then
  echo "PATH=\"\\$(sort_path \\${PATH[@]})\""
elif on_linux; then
  echo "LD_LIBRARY_PATH=\"\\$(uniq_path \\${LD_LIBRARY_PATH[@]})\""
elif on_darwin; then
  echo "DYLD_LIBRARY_PATH=\"\\$(uniq_path \\${DYLD_LIBRARY_PATH[@]})\""
fi`
PATH="\$(uniq_path \${PATH[@]})"

# other paths

# eof
END
	if [ 0 -eq $? ]; then
		echo "yes"
	else
		echo "no"
	fi
}

gen_dot_vimrc() {
	local rc="$HOME/.vimrc"
	echo -n "+ generate $rc ... "
  cat << END > "$rc"
"------------------------------------------------
" target: $rc
" author: junjiemars@gmail.com
" generated by:
"   $SH <($SH_ENV)
`if [ -f "${rc}.ori" ]; then
  echo "\" origin backup: ${rc}.ori"
fi`
"------------------------------------------------

" nocompatible
"set nocompatible

" set internal shell
`if [ "zsh" = "$SH" ]; then
	echo "set shell=zsh\ --rcs"
else
	echo "set shell=bash\ --rcfile\ ~/.bashrc"
fi`

" tabs are 2 characters
set tabstop=2

" (auto)indent uses 2 characters
set shiftwidth=2

" spaces instead of tabs
set noexpandtab

" history
set history=50

" 1000 undo levels
set undolevels=1000

" encoding
"set encoding=utf8
set fileencoding=utf8

" line number
set number
set cursorline " :p
hi cursorline cterm=none
hi cursorlinenr term=bold ctermfg=yellow gui=bold guifg=yellow

" syntax highlight
syntax enable 

" highlight search
set hlsearch " :nohl

" background dark
set background=light

" keep filetype and syntax
set hidden " :nohidden

" status bar
set ruler
"set laststatus=2

" visual bell
set novisualbell

" colorful
"set grepprg=grep\ --color=always\ -n\ \$*\ /dev/null

" search subdirs
set path+=**

" eof
END
	if [ 0 -eq $? ]; then
		echo "yes"
	else
		echo "no"
	fi
}

BEGIN=`date +%s`
echo "setup ${PLATFORM}'s $SH env ..."

gen_dot_shell_profile
gen_dot_shell_logout
gen_dot_shell_rc
gen_dot_shell_init
  
gen_dot_shell_aliases
gen_dot_shell_vars
gen_dot_shell_paths

gen_dot_vimrc $HOME/.vimrc

. $HOME/.${SH}rc


END=`date +%s`
echo 
echo "... elpased $(( ${END}-${BEGIN} )) seconds, successed."

