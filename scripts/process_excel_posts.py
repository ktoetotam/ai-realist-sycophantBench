#!/usr/bin/env python3
"""
Process Excel file with posts and convert to posts.jsonl format.
Expects first column to contain post text, one post per row.
"""

import json
import pandas as pd
from pathlib import Path
import datetime as dt
import re

def clean_text(text):
    """Clean and normalize post text."""
    if pd.isna(text):
        return ""
    
    # Convert to string if not already
    text = str(text).strip()
    
    # Remove extra whitespace and normalize line breaks
    text = re.sub(r'\s+', ' ', text)
    text = re.sub(r'\n\s*\n', '\n\n', text)
    
    return text

def infer_topic(text):
    """Simple topic inference based on keywords."""
    text_lower = text.lower()
    
    # Define topic keywords
    topics = {
        'ai_ethics': ['ethics', 'ethical', 'bias', 'fairness', 'responsible ai'],
        'prompt_engineering': ['prompt', 'prompting', 'prompt engineering'],
        'machine_learning': ['machine learning', 'ml', 'neural network', 'deep learning'],
        'artificial_intelligence': ['artificial intelligence', 'ai', 'llm', 'language model'],
        'technology': ['technology', 'tech', 'software', 'algorithm'],
        'data_science': ['data science', 'data', 'analytics', 'statistics'],
        'business': ['business', 'market', 'industry', 'enterprise'],
        'research': ['research', 'study', 'analysis', 'findings'],
        'opinion': ['think', 'believe', 'opinion', 'argue', 'claim'],
    }
    
    for topic, keywords in topics.items():
        if any(keyword in text_lower for keyword in keywords):
            return topic
    
    return 'general'

def main():
    # Paths
    excel_path = Path('../data/raw/airealistposts.xlsx')
    output_path = Path('../data/raw/posts.jsonl')
    
    if not excel_path.exists():
        print(f"Error: Excel file not found at {excel_path}")
        return
    
    print(f"Reading Excel file: {excel_path}")
    
    try:
        # Read Excel file - don't assume first row is header
        df = pd.read_excel(excel_path, header=None)
        print(f"Excel file shape: {df.shape}")
        print(f"Total rows in Excel: {len(df)}")
        
        # Use first column for post text
        post_texts = df.iloc[:, 0].dropna()
        
        print(f"Found {len(post_texts)} non-empty posts")
        
        # Convert to JSONL format
        records = []
        for idx, text in enumerate(post_texts):
            cleaned_text = clean_text(text)
            if not cleaned_text:  # Skip empty posts
                continue
                
            topic = infer_topic(cleaned_text)
            
            record = {
                "post_id": f"p{idx+1:04d}",  # p0001, p0002, etc.
                "source": "excel_import",
                "text": cleaned_text,
                "topic": topic,
                "metadata": {
                    "created": dt.datetime.now().strftime("%Y-%m-%d"),
                    "language": "en",
                    "original_row": idx + 1,  # Excel row number (1-indexed)
                    "source_file": "airealistposts.xlsx"
                }
            }
            records.append(record)
        
        # Write JSONL
        print(f"Writing {len(records)} records to {output_path}")
        with output_path.open('w', encoding='utf-8') as f:
            for record in records:
                f.write(json.dumps(record, ensure_ascii=False) + '\n')
        
        print(f"✅ Successfully created posts.jsonl with {len(records)} posts")
        
        # Show first few records
        if records:
            print("\nFirst few records:")
            for i, record in enumerate(records[:3]):
                print(f"  {record['post_id']}: {record['text'][:100]}...")
                if i >= 2:
                    break
    
    except Exception as e:
        print(f"Error processing Excel file: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()