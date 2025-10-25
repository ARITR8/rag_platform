from typing import List

from pydantic import BaseModel


class RetrieveRequest(BaseModel):
    query: str
    limit: int = 5


class Document(BaseModel):
    doc_id: str
    content: str
    score: float


class RetrieveResponse(BaseModel):
    documents: List[Document]
