#!/bin/bash

# start python virtual environment to use Ollama framework

source ~/llm/bin/activate

# run a query to LLM with a timeout of 300 seconds

timeout -v 300 python3 ./llm-query.py $1
