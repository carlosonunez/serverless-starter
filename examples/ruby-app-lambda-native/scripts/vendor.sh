#!/usr/bin/env bash

bundle install &&
  cp -R /usr/local/bundle /vendor &&
  chmod -R +x /vendor/bundle/bin
