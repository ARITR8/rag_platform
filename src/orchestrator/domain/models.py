from typing import Any, Dict, List

from pydantic import BaseModel


class QueryRequest(BaseModel):
    query: str
    limit: int = 3


class Source(BaseModel):
    doc_id: str
    snippet: str
    score: float


class QueryResponse(BaseModel):
    answer: str
    sources: List[Source]
    meta: Dict[str, Any]
