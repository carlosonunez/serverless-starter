#!/usr/bin/env bash
PROJECT_ROOT=$(dirname $0)/..
EXAMPLES_DIR=$PROJECT_ROOT/examples

usage() {
  cat <<-USAGE
$(basename $0) [example-name]
Stages an example app to the root of your project's directory.

See a list of available examples by typing "list" instead of an example name.
USAGE
}

is_valid_example() {
  test -d "${EXAMPLES_DIR}/$1"
}

wants_to_list_examples() {
  printf "$1" | grep -Eiq "^list$"
}

if test "$1" == '--help' || test "$1" == '-h'
then
  usage
  exit 0
fi

example_name=$1
if wants_to_list_examples "$example_name"
then
  find $EXAMPLES_DIR -type d -maxdepth 1 | awk -F '/' '{print $NF}' | grep -v 'examples'
  exit 0
fi

if ! is_valid_example "$example_name"
then
  >&2 echo "ERROR: Not a valid example: $example_name"
  exit 1
fi

cp -Rv $EXAMPLES_DIR/$example_name/* $PROJECT_ROOT
