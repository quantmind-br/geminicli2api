import requests
import json

# Configuration
BASE_URL = "http://localhost:8888"
HEALTH_ENDPOINT = f"{BASE_URL}/health"
OPENAI_ENDPOINT = f"{BASE_URL}/v1/chat/completions"
GEMINI_ENDPOINT = f"{BASE_URL}/v1beta/models"
API_KEY = "clara4014@"

def test_health_check():
    """Tests the health check endpoint."""
    print("--- Testing Health Check ---")
    try:
        response = requests.get(HEALTH_ENDPOINT)
        response.raise_for_status()  # Raise an exception for bad status codes
        print(f"Health Check successful: Status Code {response.status_code}")
        print("Response:", response.json())
    except requests.exceptions.RequestException as e:
        print(f"Health Check failed: {e}")
    print("\n" + "="*30 + "\n")

def test_openai_api():
    """Tests the OpenAI chat completions endpoint."""
    print("--- Testing OpenAI API ---")
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }
    data = {
        "model": "gemini-2.5-pro-preview-05-06",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Hello!"}
        ]
    }
    try:
        response = requests.post(OPENAI_ENDPOINT, headers=headers, data=json.dumps(data))
        response.raise_for_status()
        print(f"OpenAI API Test successful: Status Code {response.status_code}")
        print("Response:", response.json())
    except requests.exceptions.RequestException as e:
        print(f"OpenAI API Test failed: {e}")
        if e.response:
            print("Response content:", e.response.text)
    print("\n" + "="*30 + "\n")

def test_gemini_api():
    """Tests the Gemini models endpoint."""
    print("--- Testing Gemini API ---")
    headers = {
        "Authorization": f"Bearer {API_KEY}"
    }
    try:
        response = requests.get(GEMINI_ENDPOINT, headers=headers)
        response.raise_for_status()
        print(f"Gemini API Test successful: Status Code {response.status_code}")
        print("Response:", response.json())
    except requests.exceptions.RequestException as e:
        print(f"Gemini API Test failed: {e}")
    print("\n" + "="*30 + "\n")

if __name__ == "__main__":
    print("Starting API endpoint tests...")
    test_health_check()
    test_openai_api()
    test_gemini_api()
    print("All tests finished.")
