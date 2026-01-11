import requests
from bs4 import BeautifulSoup
import logging

logger = logging.getLogger("Scraper")

def scrape_text(url: str, max_chars: int = 5000) -> str:
    """
    Fetches the URL and returns the visible text content.
    Caps the length to avoid overflowing LLM context windows.
    """
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (compatible; OracleMind/1.0; +http://mysite.com)"
        }
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, "html.parser")
        
        # Remove unwanted tags
        for script in soup(["script", "style", "nav", "footer", "header"]):
            script.decompose()
            
        text = soup.get_text(separator="\n")
        
        # Clean up whitespace
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        clean_text = '\n'.join(chunk for chunk in chunks if chunk)
        
        logger.info(f"Successfully scraped {len(clean_text)} chars from {url}")
        return clean_text[:max_chars]
        
    except Exception as e:
        logger.error(f"Failed to scrape {url}: {e}")
        return ""
