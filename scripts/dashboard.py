"""
Blender Awesome Dashboard
Web interface for managing Blender and related services
"""
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import uvicorn
import requests
import subprocess
import os
import json
from datetime import datetime

app = FastAPI(title="Blender Awesome Dashboard", version="1.0.0")

# Templates and static files
templates = Jinja2Templates(directory="/workspace/templates")
app.mount("/static", StaticFiles(directory="/workspace/static"), name="static")

# Service endpoints
SERVICES = {
    "blender": {"port": 9876, "name": "Blender MCP"},
    "jupyter": {"port": 8888, "name": "Jupyter Lab"},
    "comfyui": {"port": 8080, "name": "ComfyUI"},
}

@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    """Main dashboard page"""
    return templates.TemplateResponse("dashboard.html", {"request": request})

@app.get("/api/status")
async def get_status():
    """Get status of all services"""
    status = {}
    for service, info in SERVICES.items():
        try:
            # Check if service is responding
            response = requests.get(f"http://localhost:{info['port']}", timeout=2)
            status[service] = {
                "status": "running",
                "port": info["port"],
                "name": info["name"]
            }
        except:
            status[service] = {
                "status": "stopped",
                "port": info["port"],
                "name": info["name"]
            }

    # Check Blender specifically
    try:
        response = requests.post("http://localhost:9876", json={"jsonrpc": "2.0", "method": "status"}, timeout=2)
        if response.status_code == 200:
            blender_data = response.json()
            status["blender"]["details"] = blender_data.get("result", {})
    except:
        pass

    return JSONResponse(status)

@app.post("/api/blender/execute")
async def execute_blender_script(request: Request):
    """Execute Python script in Blender"""
    try:
        data = await request.json()
        script = data.get("script", "")

        if not script:
            raise HTTPException(status_code=400, detail="No script provided")

        # This would need proper MCP integration
        # For now, return placeholder
        return JSONResponse({
            "status": "executed",
            "script": script[:100] + "..." if len(script) > 100 else script
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/projects")
async def get_projects():
    """Get list of projects/models"""
    try:
        projects = []
        if os.path.exists("/workspace/models"):
            for file in os.listdir("/workspace/models"):
                if file.endswith(('.blend', '.py', '.json')):
                    projects.append({
                        "name": file,
                        "type": file.split('.')[-1],
                        "path": f"/workspace/models/{file}"
                    })
        return JSONResponse(projects)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/git/{action}")
async def git_action(action: str):
    """Perform git actions"""
    try:
        if action == "status":
            result = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True, cwd="/workspace")
            return JSONResponse({"status": result.stdout.strip()})
        elif action == "commit":
            result = subprocess.run(["git", "add", "."], capture_output=True, text=True, cwd="/workspace")
            if result.returncode == 0:
                result = subprocess.run(["git", "commit", "-m", f"Auto-commit {datetime.now()}"], capture_output=True, text=True, cwd="/workspace")
                return JSONResponse({"status": "committed" if result.returncode == 0 else "failed"})
        return JSONResponse({"error": "Unknown action"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    print("🖥️ Starting Blender Awesome Dashboard on port 3000")
    uvicorn.run(app, host="0.0.0.0", port=3000)