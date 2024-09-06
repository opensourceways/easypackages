from fastembed.embedding import DefaultEmbedding
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, VectorParams
import time
import re


def read_feature_txt(file_path):
    try:
        with open(file_path, 'r') as file:
            data = file.read()
        cleaned_text = re.sub(r'[{}[\]()@.#\\_\':\/-]', '', data)
        return cleaned_text
    except FileNotFoundError:
        print(f"文件 '{file_path}' 未找到")
        return None
    except IOError as e:
        print(f"读取文件时出错: {e}")
        return None


data0 = read_feature_txt('tmpq.txt')
data1 = read_feature_txt('test_1.txt')
data2 = read_feature_txt('test_2.txt')

# Load a FastEmbed model
fastembed_model = DefaultEmbedding()
# Same dataset as the first benchmark
# more sentences
sentences = [data0, data1]
# Generate embeddings with FastEmbed
start_time = time.time()
fast_embeddings = list(fastembed_model.embed(sentences))
end_time = time.time()
print("Time taken to generate embeddings with FastEmbed:",
      end_time - start_time, "seconds")
# Connect to Qdrant and upload FastEmbed embeddings
# client = QdrantClient(host='localhost', port=6333)
client = QdrantClient(url="http://localhost:6333")
collection_name = 'test_simi'
print(len(fast_embeddings[0]))
vector_param = VectorParams(size=len(fast_embeddings[0]),
                            distance=Distance.COSINE)
print(client.collection_exists(collection_name=collection_name))
if not client.collection_exists(collection_name=collection_name):
    client.create_collection(collection_name=collection_name,
                             vectors_config=vector_param)
client.upload_collection(collection_name=collection_name,
                         vectors=fast_embeddings)
# Perform a search query
# using the first sentence embedding as a query
query_vector = list(fastembed_model.embed([data2]))
print(query_vector)
start_time = time.time()
search_results = client.search(collection_name=collection_name,
                               query_vector=query_vector[0],
                               limit=2, score_threshold=0.7)
end_time = time.time()
print("search with FastEmbed:", end_time - start_time, "seconds")
print(search_results)
