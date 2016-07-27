#!/bin/bash

OS=${OSTYPE:-linux} ## uname -o
case $OS in
  linux*) GREP="grep -P ";;
  darwin*) GREP="grep -e ";;
  bsd*) GREP="grep -e ";;
  *) exit 1;;
esac
CLOJURE_PATH=${CLOJURE_PATH:-"/opt/bin/clojure.git/target"}
CLOJURE_JAR=$(ls ${CLOJURE_PATH%/}/*.jar | ${GREP} 'clojure-\d\.\d\d*\.\d\d*\.jar')
CLASSPATH=${CLOJURE_JAR}:${CLASSPATH}
export JAVA_OPTS=${JAVA_OPTS:-""}

if [[ 0 -eq $(rlwrap -v 2>&1 1>/dev/null;echo $?) ]]; then
  rlwrap java -cp $CLASSPATH clojure.main "$@"
else
  java -cp $CLASSPATH clojure.main "$@"
fi