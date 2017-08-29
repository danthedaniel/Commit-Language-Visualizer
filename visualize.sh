#!/bin/bash

ruby read_commits.rb "$1" "$2" | python streamgraph.py
