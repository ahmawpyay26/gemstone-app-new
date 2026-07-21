import json
import urllib.request
import urllib.error

run_id = 29833190878
repo = "ahmawpyay26/gemstone-app-new"

try:
    url = f"https://api.github.com/repos/{repo}/actions/runs/{run_id}/jobs"
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode())
        
    # Find the failed step
    for job in data['jobs']:
        if job['conclusion'] == 'failure':
            print(f"Job: {job['name']}")
            for step in job['steps']:
                if step['conclusion'] == 'failure':
                    print(f"  Failed Step: {step['name']}")
                    print(f"  Duration: {step['started_at']} to {step['completed_at']}")
except Exception as e:
    print(f"Error: {e}")
