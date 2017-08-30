#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <user> <api_token>" >&2
  exit 1
fi

ruby read_commits.rb "$1" "$2" | python streamgraph.py
