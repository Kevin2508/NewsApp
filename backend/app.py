import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import TruncatedSVD
from sklearn.metrics.pairwise import cosine_similarity
from supabase import create_client

# Load dataset
df = pd.read_csv("scraped_articles_api.csv").fillna("")
if 'id' not in df.columns:
    df['id'] = df.index
df["combined_text"] = df["title"] + " " + df["description"] + " " + df["content"]

# TF-IDF Vectorizer
vectorizer = TfidfVectorizer(stop_words="english", max_features=5000)
tfidf_matrix = vectorizer.fit_transform(df["combined_text"])

# LSA (TruncatedSVD)
svd = TruncatedSVD(n_components=100, random_state=42)
lsa_matrix = svd.fit_transform(tfidf_matrix)

# Connect to Supabase
url = "https://epbwesqrwnpjexbsrftl.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwYndlc3Fyd25wamV4YnNyZnRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIxMjczMjAsImV4cCI6MjA1NzcwMzMyMH0.de8-fcXPn8CBHoHcRM7j0SPfxuFWOxqm4yftIDyoCQ8"
supabase = create_client(url, key)

# Function to get recommendations for a category
def get_recommendations(category, top_n=5):
    query_tfidf = vectorizer.transform([category])
    query_lsa = svd.transform(query_tfidf)
    cos_sims = cosine_similarity(query_lsa, lsa_matrix)[0]
    top_indices = cos_sims.argsort()[::-1][:top_n]
    recommendations = []
    for idx in top_indices:
        article = df.iloc[idx]
        recommendations.append({
            "category": category,
            "title": article["title"],
            "url": article["url"],
            "description": article["description"],
            "content": article["content"],
            "image_url": article["image_url"],
            "published_at": article["published_at"],
            "author": article["author"],
            "similarity_score": float(cos_sims[idx]),
        })
    return recommendations

# Generate recommendations for all categories
categories = [
    "General", "Business", "Technology", "Entertainment", "Sports",
    "Health", "Science", "Politics", "Environment", "Travel",
    "Food", "Education", "Finance", "World", "Culture", "Crime"
]
all_recommendations = []
for category in categories:
    recommendations = get_recommendations(category, top_n=5)
    all_recommendations.extend(recommendations)

# Insert recommendations into Supabase
response = supabase.table("recommendations").insert(all_recommendations).execute()

if "error" in response.data:
    print(f"Error inserting data: {response.data['error']}")
else:
    print("Recommendations successfully stored in Supabase!")
