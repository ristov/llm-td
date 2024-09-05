#!/bin/bash

# start python virtual environment to use Ollama framework

source ~/llm/bin/activate

# run a query to LLM

python3 ./llm-query.py $1
