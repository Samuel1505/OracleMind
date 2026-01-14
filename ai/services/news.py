import os
import logging
from typing import List, Dict
from newsapi import NewsApiClient

logger = logging.getLogger("NewsService")

class NewsService:
    def __init__(self):
        api_key = os.getenv("NEWSAPI_KEY")
        if not api_key:
            logger.warning("NEWSAPI_KEY not found. News fetching will be limited.")
            self.client = None
        else:
            self.client = NewsApiClient(api_key=api_key)
    
    def search_news(self, query: str, max_results: int = 5) -> str:
        """
        Search for news articles related to the query.
        Returns a formatted string with article titles, descriptions, and URLs.
        """
        if not self.client:
            return "NewsAPI key not configured. Unable to fetch news."
        
        try:
            logger.info(f"Fetching news for query: {query}")
            response = self.client.get_everything(
                q=query,
                language='en',
                sort_by='relevancy',
                page_size=max_results
            )
            
            if response['status'] != 'ok':
                return f"News API error: {response.get('message', 'Unknown error')}"
            
            articles = response.get('articles', [])
            if not articles:
                return f"No news articles found for '{query}'"
            
            # Format articles
            result = f"Found {len(articles)} news articles for '{query}':\n\n"
            for i, article in enumerate(articles, 1):
                title = article.get('title', 'No title')
                description = article.get('description', 'No description')
                url = article.get('url', '')
                source = article.get('source', {}).get('name', 'Unknown')
                published = article.get('publishedAt', '')
                
                result += f"{i}. **{title}**\n"
                result += f"   Source: {source} | Published: {published}\n"
                result += f"   {description}\n"
                result += f"   URL: {url}\n\n"
            
            logger.info(f"Successfully fetched {len(articles)} articles")
            return result
            
        except Exception as e:
            logger.error(f"Error fetching news: {e}")
            return f"Error fetching news: {str(e)}"
