#!/bin/bash
#------------------------------------------------
# target: bash env setup script	
# author: junjiemars@gmail.com
#------------------------------------------------

HOME=${HOME%/}
PLATFORM=`uname -s 2>/dev/null`
ARCH=`uname -m 2>/dev/null`
GITHUB_H="${GITHUB_H:-https://raw.githubusercontent.com/junjiemars/kit/master}"
curl='curl -sL '
declare -a BASH_S=(\
	'.bash_init' \
  '.bash_aliases' \
  '.bash_vars' \
  '.bash_paths' \
  '.bashrc' \
  '.profile' \
  '.bash_profile' \
  '.bash_logout' \
  '.vimrc' \
  )

save_as() {
  local f="$HOME/$1"
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
  if [[ $p =~ ^[a-zA-Z]:[\/\\].*$ ]]; then
    echo "\\$p" | \
      sed -e 's#^\\\([a-zA-Z]\):\\#\\\1\\#' | \
      sed -e 's#\\#\/#g' | \
      sed -e 's# #\\ #g'
  else
    echo "$p"
  fi
}

sort_path() {
  # Windows: let MSYS_NT and user defined commands first
	local awk='/bin/awk'
	local tr='/usr/bin/tr'
	local grep='/usr/bin/grep'
	local paths="$1"
	local opt_p="`/usr/bin/dirname $OPT_RUN`"
	local opt=
	local win_p="^/c/"

	opt="`echo -n "$paths" | $tr ':' '\n' | \
		$grep "$opt_p" | $tr '\n' ':' `"
  local car="`echo -n "$paths" | $tr ':' '\n' | \
		$grep -v "$opt_p" | $grep -v "$win_p" | $tr '\n' ':' `"
  local cdr="`echo -n "$paths" | $tr ':' '\n' | \
    $grep "$win_p" | $tr '\n' ':' `"
  local new="`echo -n "${car}${opt:+$opt }${cdr}" | \
		$awk '!xxx[$0]++' | sed -e 's#:$##' -e 's#:\  *\/#:\/#g' `"
  echo -n "${new}" 
}

delete_tail_lines() {
	local h="$1"
  local lines="$2"
	local f="$3"

	sed_opt_i="-i.pre"
	`on_darwin` && sed_opt_i="-i .pre"

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

gen_dot_bash_profile() {
  cat << END > "$1"
#------------------------------------------------
# target: call $HOME/.bashrc
# author: junjiemars@gmail.com
# generated by Kit (https://github.com/junjiemars/kit)
#------------------------------------------------

test -r \$HOME/.bashrc && . \$HOME/.bashrc
END
}

gen_dot_bash_logout() {
  cat << END > "$1"
#------------------------------------------------
# target: call when logout
# author: junjiemars@gmail.com
# generated by Kit (https://github.com/junjiemars/kit)
#------------------------------------------------

# ~/.bash_logout: executed by bash(1) when login shell exits.
# when leaving the console clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

END
}

gen_empty_dot_bashrc() {
  [ -f "$1" ] && return 0

  cat << END > "$1"
#------------------------------------------------
# target: bashrc default
# author: junjiemars@gmail.com
# generated by Kit (https://github.com/junjiemars/kit)
#------------------------------------------------

END
}

gen_dot_bash_init() {
  cat << END > "$1"
#!/bin/bash
#------------------------------------------------
# target: init script
# author: junjiemars@gmail.com
# generated by Kit (https://github.com/junjiemars/kit)
#------------------------------------------------

export HOME=\${HOME%/}

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

`
declare -f on_windows_nt
`

`
declare -f on_darwin
`

`
declare -f on_linux
`


if test -n "\$PROMPT_COMMAND"; then
  if \`inside_docker_p\` || \`inside_emacs_p\`; then
    export PROMPT_COMMAND=''
  fi
fi

case ".\$PS1" in
	.|.\\s*|.[*|.\\[\\*|.\\h:*)
		PS1="\u@\h:\w\$ "
		;;
	*)
		;;
esac

if test -z "\$TERM" || test "dumb" = "\$TERM"; then
  export TERM="xterm"
fi


#PREFIX=/opt

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
  echo -e "if test -z \"\$LANG\"; then"
  echo -e "  export LANG=en_US.UTF-8"
  echo -e "fi"
fi
`

# vars, paths, and aliases
#----------

test -f \$HOME/.bash_vars && . \$HOME/.bash_vars
test -f \$HOME/.bash_paths && . \$HOME/.bash_paths
test -f \$HOME/.bash_aliases && . \$HOME/.bash_aliases 

# epilogue
#----------

END
}

gen_dot_bash_aliases() {
  cat << END > "$1"
#!/bin/bash
#------------------------------------------------
# target: aliases on bash environment
# author: junjiemars@gmail.com
# generated by Kit (https://github.com/junjiemars/kit)
#------------------------------------------------

alias ..1='cd ../'
alias ..2='cd ../../'
alias ..3='cd ../../../'
alias ..4='cd ../../../../'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

function exist_p() {
    type -p \${1} &>/dev/null; echo \$?
}

function diff_p() {
    diff \${1} \${2} &>/dev/null; echo \$?
}

has_rlwrap=\$(exist_p 'rlwrap')

if \`on_darwin\`; then
  alias ls='ls -G'
  alias ll='ls -lh -G'
  alias l='ls -CF -G'
  alias tailf='tail -f'
  alias stat='stat -x'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh --color=auto'
  alias l='ls -CF --color=auto'
fi

alias_racket() {
	if [ 0 -eq \$has_rlwrap ]; then
		local p_racket=\$(exist_p 'racket')
		if [ 0 -eq \$p_racket ]; then
			local v
			IFS='.' read -a v <<< "\`racket -v|sed 's/.*v\([0-9].[0-9]\).*/\1/g'\`"
			if [ 67 -gt \$(( \${v[0]}*10+\${v[1]} )) ]; then
				alias racket='rlwrap racket'
			fi
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

END
}

gen_dot_bash_vars() {
  cat << END > "$1"
#!/bin/bash
#------------------------------------------------
# target: vars on bash environment
# author: junjiemars@gmail.com
# generated by Kit (https://github.com/junjiemars/kit)
#------------------------------------------------

if \`on_windows_nt\`; then
  if [ -d "/d/" ]; then
    [ -d "/d/opt" ] || mkdir -p "/d/opt"
    PREFIX="\${PREFIX:-/d/opt}"
  else
    [ -d "/c/opt" ] || mkdir -p "/c/opt"
    PREFIX="\${PREFIX:-/c/opt}"
  fi  
else
  PREFIX="\${PREFIX:-/opt}"
fi

OPT_RUN="\${OPT_RUN:-\${PREFIX}/run}"
OPT_OPEN="\${OPT_OPEN:-\${PREFIX}/open}"

[ -d "\${OPT_RUN}" ] && export OPT_RUN=\${OPT_RUN}
[ -d "\${OPT_OPEN}" ] && export OPT_OPEN=\${OPT_OPEN}

check_java_env() {
	if \`on_darwin\`; then
      local java_home='/usr/libexec/java_home'
      [ -L "\${java_home}" ] && export JAVA_HOME=\`\${java_home} 2>/dev/null\`
	elif \`on_linux\`; then
      local javac=\`type -p javac 2>/dev/null\`
      [ -n "\${javac}" ] && local java_home=\$(readlink -f "\${javac}" | sed 's:/bin/javac::')
      [ -n "\${java_home}" ] && [ -z "\$JAVA_HOME" ] && export JAVA_HOME="\${java_home}"
	fi
}

check_java_env

# declare vars

END
}

gen_dot_bash_paths() {
  cat << END > "$1"
#!/bin/bash
#------------------------------------------------
# target: paths on bash environment
# author: junjiemars@gmail.com
# generated by Kit (https://github.com/junjiemars/kit)
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
if \`on_windows_nt\`; then
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

# chain basis PREFIX/opt/run/{bin,sbin} paths
if [ -n "\${OPT_RUN}" ]; then
	PATH="\`append_path \${OPT_RUN}/bin \${PATH[@]}\`"
	PATH="\`append_path \${OPT_RUN}/sbin \${PATH[@]}\`"
`
  if ! on_windows_nt; then
	  echo "  LD_LIBRARY_PATH=\"\\$(append_path \\${OPT_RUN}/lib \\${LD_LIBRARY_PATH[@]})\""
  fi
`
fi

# java home
if [ -n "\${JAVA_HOME}" ]; then
`
  if on_windows_nt; then
    echo "  JAVA_HOME=\\$(posix_path \"\\${JAVA_HOME}\")"
  fi
`
  PATH="\`append_path \"\${JAVA_HOME}\" \$PATH\`"
  PATH="\`append_path \"\${JAVA_HOME}/bin\" \$PATH\`"
fi


PATH="\$(uniq_path \${PATH[@]})"
`
if on_windows_nt; then
  echo "PATH=\"\\$(sort_path \\${PATH[@]})\""
else
  echo "LD_LIBRARY_PATH=\"\\$(uniq_path \${LD_LIBRARY_PATH[@]})\""
fi
`

# other paths

END
}

set_vim_path_var() {
  local f=$1
  shift
  local inc_lns=("${@}")
  local inc_ln="${#inc_lns[@]}"
  local cc_header="\" cc include path"
  local t=0

  delete_tail_lines "${cc_header}" "yes" "$f"

  echo -e "${cc_header} :check_cc_include" >> $f
  for i in "${inc_lns[@]}"; do
		local ln=$(echo "$i" | sed 's_ _\\\\\\ _g')
    echo "set path+=${ln}" >> $f
  done
}

check_linux_cc_include() {
	local inc_list=$1
	local vimrc=$2
  if `type -p cc &>/dev/null`; then
    local cc_out="`echo '' | cc -v -E 2>&1 >/dev/null - \
									| awk '/#include <...> search starts here:/,/End of search list./'`"
    [ -n "$cc_out" ] || return 1

		local inc_lns=()
		IFS=$'\n'
		for l in `echo "$cc_out"`; do
			inc_lns+=($(echo "$l" | sed 's/^ //'))
		done
		unset IFS

		cat /dev/null > "$inc_list"
		local inc_ln="${#inc_lns[@]}"
		if [[ 2 -lt "$inc_ln" ]]; then
			local inc_paths=("${inc_lns[@]:1:$(( inc_ln-2  ))}")
			echo "${inc_paths[@]}" >> "$inc_list"
			set_vim_path_var "${vimrc}" "${inc_paths[@]}"
    fi
  fi
}

find_vctools() {
 	local vctools="`env|grep 'VS[0-9][0-9]*COMNTOOLS'|sed 's#^VS[0-9]*COMNTOOLS=\(.*\)$#\1#g'`"

  if [ -n "$vctools" ]; then
    vctools="`( cd "$vctools\..\..\VC\Auxiliary\Build" && pwd )`"
    vctools="`echo "$vctools" | sed -e 's#^\/\([a-z]\)#\u\1:#'`"
    if [ -d "$vctools" ]; then
      echo "$vctools"
      return 0
    fi
  fi

  local vswhere="`posix_path \"${PROGRAMFILES} (x86)/Microsoft Visual Studio/Installer/vswhere.exe\"`"
  if [ -f "${vswhere}" ]; then
    vctools="`cd \"$(dirname \"${vswhere}\")\"; ./vswhere.exe -latest -property installationPath`"
    if [ -n "$vctools" ]; then
      vctools="${vctools}\VC\Auxiliary\Build"
      if [ -d "$vctools" ]; then
        echo "$vctools"
        return 0
      fi
    fi
  fi

  return 1
}

check_win_cc_include() {
	local inc_list="$1"
  local vimrc="$2"
  local inc_bat="$3"
  local t=0

	local vctools="`find_vctools`"
  t=$?
	[ 0 -eq $t -a -n "${vctools[@]}" ] || return 0

  local warch=$ARCH
  local warch64=
  if `echo $ARCH | grep 64 &>/dev/null`; then
    warch64=64
    warch=x64
  else
    warch=x86
  fi

  cat <<END > "$inc_bat"
@echo off
REM %userprofile%/.vc-inc.bat
REM generated by Nore (https://github.com/junjiemars/nore)
set wpwd=%cd%
cd /d "$vctools"

if "%1" == "" goto :default
if "%1" == "x86" goto :x86
if "%1" == "x86_arm" goto :x86
if "%1" == "x64" goto :x86_64
if "%1" == "x86_amd64" goto :x86_64
if "%1" == "x86_64" goto :x86_64

:default
call vcvarsall.bat ${warch}
set CC=cl
set AS=ml${warch64}
goto :echo_inc

:x86
call vcvarsall.bat %* 
set CC=cl
set AS=ml
goto :echo_inc

:x86_64
call vcvarsall.bat %*
set CC=cl
set AS=ml64
goto :echo_inc

:echo_inc
cd /d %wpwd%
echo "%INCLUDE%" 
END

	[ -f "$inc_bat" ] || return 1
	chmod u+x "$inc_bat"

 	local include=$($inc_bat | tail -n1) 
	[ -n "$include" ] || return 1

	cat /dev/null > "$inc_list"
 	include=$(echo $include | sed 's#\"##g')
 	local inc_lns=()
 	IFS=$';'
 	for i in `echo "${include}"`; do
		local ln=$(echo "\\${i}"|sed -e 's#^\\\([a-zA-Z]\):\\#\\\l\1\\#' -e 's#\\#\/#g')
		echo "'$ln'" >> "$inc_list"
		inc_lns+=( "$ln" )
 	done
 	unset IFS

 	set_vim_path_var "${vimrc}" "${inc_lns[@]}"
}


BEGIN=`date +%s`
echo "setup $PLATFORM bash env ..."

for i in "${BASH_S[@]}"; do
  `save_as "$i"`
done


gen_dot_bash_profile $HOME/.bash_profile
gen_dot_bash_logout $HOME/.bash_logout
gen_empty_dot_bashrc $HOME/.bashrc

gen_dot_bash_init $HOME/.bash_init
  
delete_tail_lines '# call .bash_init' "yes" "$HOME/.bashrc" 

echo -e "# call .bash_init" >> $HOME/.bashrc
cat << END >> $HOME/.bashrc
test -f \${HOME%/}/.bash_init && . \${HOME%/}/.bash_init
export PATH
`
if ! on_windows_nt; then
  echo "export LD_LIBRARY_PATH"
fi
`

END

gen_dot_bash_aliases $HOME/.bash_aliases
gen_dot_bash_vars $HOME/.bash_vars
gen_dot_bash_paths $HOME/.bash_paths

${curl} ${GITHUB_H}/ul/.vimrc -o $HOME/.vimrc


. $HOME/.bashrc

case ${PLATFORM} in
  Linux)
    check_linux_cc_include $HOME/.cc-inc.list $HOME/.vimrc
    ;;
  MSYS_NT*|MINGW*)
    check_win_cc_include $HOME/.cc-inc.list $HOME/.vimrc $HOME/.vc-inc.bat
    ;;
  *)
    ;;
esac

END=`date +%s`
echo 
echo "... elpased $(( ${END}-${BEGIN} )) seconds, successed."

