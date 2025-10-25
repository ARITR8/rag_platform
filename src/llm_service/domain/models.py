# This file contains the domain models for the LLM service.
####  model (business rule validator in the request) #####
from typing import List

from pydantic import BaseModel


# vector Database will be returning this context..
class ContextItem(BaseModel):
    doc_id: str
    content: str

    ##### {"doc_id": "123", "content": "Capital of India is Delhi "} #####
    ##### {"doc_id": "123", "content": "India is Delhi and close to UP"} #####


class GenerateRequest(BaseModel):
    query: str
    context: List[ContextItem]


class GenerateResponse(BaseModel):
    response: str
