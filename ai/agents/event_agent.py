import json
import logging
import os
import time
from typing import List, Dict, Any
from dotenv import load_dotenv

from langchain_openai import ChatOpenAI
from langchain_community.tools import DuckDuckGoSearchRun
from langchain_core.tools import Tool
from langgraph.prebuilt import create_react_agent
from langchain_core.messages import SystemMessage, HumanMessage

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("EventAgent")

from ai.services.scraper import scrape_text
from ai.services.news import NewsService

class EventAgent:
    def __init__(self, model: str = "google/gemma-2-9b-it:free"):
        self.model_name = model
        api_key = os.getenv("OPENROUTER_API_KEY")
        if not api_key:
            logger.warning("OPENROUTER_API_KEY not found.")

        # 1. Initialize LLM
        self.llm = ChatOpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=api_key,
            model=model,
            temperature=0.1,
        )

        # 2. Initialize services
        self.search_tool = DuckDuckGoSearchRun()
        self.news_service = NewsService()
        
        def scrape_tool_func(url: str) -> str:
            """Scrapes a specific URL for content."""
            return scrape_text(url, max_chars=3000)
        
        def news_tool_func(query: str) -> str:
            """Fetches recent news articles about a topic."""
            return self.news_service.search_news(query, max_results=3)

        self.tools = [
            Tool(
                name="WebSearch",
                func=self.search_tool.invoke,
                description="Useful for finding general information about the event. Input should be a search query."
            ),
            Tool(
                name="NewsAPI",
                func=news_tool_func,
                description="Useful for finding recent news articles from major news sources. Input should be a search query like 'Bitcoin ETF SEC approval'."
            ),
            Tool(
                name="ScrapeURL",
                func=scrape_tool_func,
                description="Useful for reading the full content of a specific URL to get details. Input should be a URL string."
            )
        ]

        # 3. Create Agent (LangGraph)
        # LangGraph's create_react_agent handles the prompt internally or accepts specific args.
        # We inject our persona via the state_modifier or system prompt.
        
        system_instructions = """You are an impartial AI Oracle for a prediction market.
Your job is to determine the outcome of a Yes/No question based strictly on the provided evidence.
You must output valid JSON only in your final answer.

Output Format (JSON):
{
    "outcome": boolean,
    "confidence": float,
    "reasoning": "string"
}
Do not wrap the JSON in markdown code blocks. Just valid JSON."""

        self.agent = create_react_agent(self.llm, self.tools, prompt=system_instructions)


    def analyze(self, question: str, sources: List[str]) -> Dict[str, Any]:
        """
        Runs the LangGraph agent to determine the verdict.
        """
        logger.info(f"Analyzing with LangGraph Agent ({self.model_name})...")
        
        context_str = ", ".join(sources)
        input_message = f"Question: {question}\nInitial Sources: {context_str}\nProvide your final verdict in JSON."
        
        try:
            # LangGraph invoke returns final state
            result = self.agent.invoke({"messages": [HumanMessage(content=input_message)]})
            
            # Extract final message
            messages = result.get("messages", [])
            if not messages:
                raise ValueError("No messages returned.")
                
            last_message = messages[-1]
            output_str = last_message.content
            
            # Clean up markdown
            output_str = output_str.strip()
            if output_str.startswith("```json"):
                output_str = output_str[7:]
            if output_str.startswith("```"):
                output_str = output_str[3:]
            if output_str.endswith("```"):
                output_str = output_str[:-3]
            
            data = json.loads(output_str)
            
            return {
                "marketId": "unknown",
                "outcome": bool(data.get("outcome", False)),
                "confidence": float(data.get("confidence", 0.0)),
                "sources": sources,
                "reasoning": data.get("reasoning", "LangGraph Agent decision.")
            }
            
        except Exception as e:
            logger.error(f"LangGraph execution failed: {e}")
            return {
                "marketId": "error",
                "outcome": False,
                "confidence": 0.0,
                "reasoning": f"Agent Error: {str(e)}",
                "timestamp": int(time.time())
            }

if __name__ == "__main__":
    agent = EventAgent()
    q = "Did the Bitcoin ETF get approved by the SEC?"
    s = ["https://www.sec.gov/news/press-release/2024-3"]
    print(agent.analyze(q, s))
