from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import litellm
import os
from typing import Optional

app = FastAPI(title="LiteLLM Chat Backend")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration from environment variables
LLM_API_BASE = os.getenv("LLM_API_BASE", "")
LLM_API_KEY = os.getenv("LLM_API_KEY", "")
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-3.5-turbo")

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    response: str

class ErrorResponse(BaseModel):
    error: str

@app.get("/health")
async def health_check():
    """Health check endpoint for Kubernetes."""
    return {"status": "healthy"}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Chat endpoint that forwards messages to LLM via LiteLLM.
    """
    try:
        if not request.message.strip():
            raise HTTPException(status_code=400, detail="Message cannot be empty")

        # Call LLM via LiteLLM
        kwargs = {
            "model": LLM_MODEL,
            "messages": [{"role": "user", "content": request.message}],
            "api_key": LLM_API_KEY,
        }

        # Add api_base if provided (for custom/OpenAI-compatible endpoints)
        if LLM_API_BASE:
            kwargs["api_base"] = LLM_API_BASE

        response = litellm.completion(**kwargs)

        # Extract response text
        assistant_message = response.choices[0].message.content

        return ChatResponse(response=assistant_message)

    except Exception as e:
        print(f"Error calling LLM: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get response from LLM: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
