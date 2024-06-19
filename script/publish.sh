#!/usr/bin/env bash
# run from project root
# set -x
set -e

# shared by all standalone figures
cp -r fluid dist/app
cp -r web/css dist/app

for FILE in src/Publish/*.purs; do
   echo $FILE
   NAME=$(basename $FILE .purs)
   NAME_LISP_CASE=$(echo $NAME | sed 's/\([A-Z]\)/-\1/g' | tr 'A-Z' 'a-z' | sed 's/^-//')
   echo $NAME_LISP_CASE

   # turn into npm script?
   rm -rf dist/app/$NAME_LISP_CASE
   mkdir -p dist/app/$NAME_LISP_CASE
   yarn spago build --purs-args '--strict --censor-codes=UserDefinedWarning'
   yarn purs-backend-es bundle-app --main Publish.$NAME --to dist/app/$NAME_LISP_CASE/app.js

   cp web/template.html dist/app/$NAME_LISP_CASE/index.html
   done