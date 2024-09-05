import sys

from langchain_community.llms import Ollama
llm_model = Ollama(model=sys.argv[1], temperature=0)

prompt = ""

for line in sys.stdin:
  prompt += line

print(llm_model.invoke(prompt))
