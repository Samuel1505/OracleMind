import logging
import asyncio
import time
from typing import List, Dict, Any
from ai.agents.event_agent import EventAgent

logger = logging.getLogger("Aggregator")

class ConsensusAggregator:
    def __init__(self, models: List[str] = None):
        # Use available OpenRouter models (not all free models work)
        self.models = models or [
            "mistralai/devstral-2512:free",
            "arcee-ai/trinity-mini:free",
            "nvidia/nemotron-nano-9b-v2:free"
        ]
        self.agents = [EventAgent(model=m) for m in self.models]

    async def aggregate(self, question: str, sources: List[str]) -> Dict[str, Any]:
        """
        Runs analysis across multiple models and computes a consensus verdict.
        """
        logger.info(f"Starting aggregation with {len(self.agents)} agents...")
        
        # Run agents in parallel (using threads or async wrapper if agent was async, 
        # but since Agent is sync blocking requests, we might use run_in_executor in real app.
        # For simplicity here, we stick to sequential loop or basic ThreadPool if needed.
        # Given this is likely run in an async FastAPI context, we'll assume blocking is okay for MVP 
        # or wrapping in to_thread is better.)
        
        results = []
        for agent in self.agents:
            try:
                # In production, use asyncio.to_thread(agent.analyze, ...)
                res = agent.analyze(question, sources)
                results.append(res)
            except Exception as e:
                logger.error(f"Agent {agent.model_name} failed: {e}")

        if not results:
            return {
                "marketId": "error",
                "outcome": False,
                "confidence": 0.0,
                "reasoning": "All agents failed.",
                "timestamp": int(time.time()),
                "sources": sources
            }

        # Filter out error responses (those with marketId == "error")
        valid_results = [r for r in results if r.get("marketId") != "error"]
        
        if not valid_results:
            return {
                "marketId": "error",
                "outcome": False,
                "confidence": 0.0,
                "reasoning": "All agents returned errors.",
                "timestamp": int(time.time()),
                "sources": sources
            }

        # Compute Consensus (Majority Vote) using only valid results
        yes_votes = len([r for r in valid_results if r["outcome"] is True])
        no_votes = len([r for r in valid_results if r["outcome"] is False])
        
        final_outcome = yes_votes > no_votes
        
        # Filter for winning side to compute average confidence
        winning_verdicts = [r for r in valid_results if r["outcome"] == final_outcome]
        if not winning_verdicts:
             avg_confidence = 0.0
        else:
             avg_confidence = sum(r["confidence"] for r in winning_verdicts) / len(winning_verdicts)

        # Consolidate reasoning
        reasoning_summary = f"Consensus Reached (Valid: {len(valid_results)}/{len(results)}):\n"
        for i, r in enumerate(results):
            model_name = self.models[i] if i < len(self.models) else "unknown"
            if r.get("marketId") == "error":
                reasoning_summary += f"- [{model_name}]: ERROR - {r.get('reasoning', 'Unknown error')}\n"
            else:
                reasoning_summary += f"- [{model_name}]: {r['outcome']} ({r['confidence']:.2f}) -> {r['reasoning'][:100]}...\n"

        logger.info(f"Consensus: {final_outcome} (Yes:{yes_votes} No:{no_votes}) Confidence: {avg_confidence}")

        return {
            "marketId": "consensus",
            "outcome": final_outcome,
            "confidence": avg_confidence,
            "timestamp": valid_results[0].get("timestamp", int(time.time())),
            "sources": sources,
            "reasoning": reasoning_summary
        }
