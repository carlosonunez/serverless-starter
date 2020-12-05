#!/usr/bin/env bash
func=$1
environment=${2:-integration}

if ! test -f docker-compose.$environment.yml
then
  >&2 echo "ERROR: Invalid environment: $environment"
  exit 1
fi

FUNCTION_NAME=$func ENVIRONMENT=$environment make logs
