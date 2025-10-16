// Blender Awesome Dashboard JavaScript

// Global variables
let statusInterval;

// Initialize dashboard
document.addEventListener('DOMContentLoaded', function() {
    updateStatus();
    statusInterval = setInterval(updateStatus, 5000); // Update every 5 seconds
});

// Update services status
async function updateStatus() {
    try {
        const response = await fetch('/api/status');
        const status = await response.json();

        const container = document.getElementById('services-status');
        container.innerHTML = '';

        for (const [service, info] of Object.entries(status)) {
            const div = document.createElement('div');
            div.className = `service-status ${info.status}`;
            div.innerHTML = `
                <i class="fas fa-${info.status === 'running' ? 'check-circle' : 'times-circle'}"></i>
                <strong>${info.name}</strong> (${info.port})
                ${info.details ? `<br><small>${JSON.stringify(info.details)}</small>` : ''}
            `;
            container.appendChild(div);
        }
    } catch (error) {
        console.error('Failed to update status:', error);
        document.getElementById('services-status').innerHTML =
            '<div class="text-danger"><i class="fas fa-exclamation-triangle"></i> Failed to load status</div>';
    }
}

// Load projects
async function loadProjects() {
    try {
        const response = await fetch('/api/projects');
        const projects = await response.json();

        const container = document.getElementById('projects-list');
        container.innerHTML = '';

        if (projects.length === 0) {
            container.innerHTML = '<div class="text-muted">No projects found</div>';
            return;
        }

        projects.forEach(project => {
            const div = document.createElement('div');
            div.className = 'project-item';
            div.innerHTML = `
                <strong>${project.name}</strong><br>
                <small class="text-muted">${project.type.toUpperCase()}</small>
            `;
            container.appendChild(div);
        });
    } catch (error) {
        console.error('Failed to load projects:', error);
        document.getElementById('projects-list').innerHTML =
            '<div class="text-danger"><i class="fas fa-exclamation-triangle"></i> Failed to load projects</div>';
    }
}

// Git operations
async function checkGitStatus() {
    try {
        const response = await fetch('/api/git/status');
        const result = await response.json();
        document.getElementById('git-status').innerHTML = result.status || 'No changes';
    } catch (error) {
        document.getElementById('git-status').innerHTML = '<span class="text-danger">Failed to check status</span>';
    }
}

async function commitChanges() {
    try {
        const response = await fetch('/api/git/commit', { method: 'POST' });
        const result = await response.json();
        if (result.status === 'committed') {
            document.getElementById('git-status').innerHTML = '<span class="text-success">Changes committed</span>';
        } else {
            document.getElementById('git-status').innerHTML = '<span class="text-danger">Commit failed</span>';
        }
    } catch (error) {
        document.getElementById('git-status').innerHTML = '<span class="text-danger">Failed to commit</span>';
    }
}

// Execute Blender script
async function executeBlenderScript() {
    const script = document.getElementById('blender-script').value;
    if (!script.trim()) {
        alert('Please enter a script to execute');
        return;
    }

    try {
        const response = await fetch('/api/blender/execute', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ script: script })
        });
        const result = await response.json();
        document.getElementById('blender-output').innerHTML = JSON.stringify(result, null, 2);
    } catch (error) {
        document.getElementById('blender-output').innerHTML = `Error: ${error.message}`;
    }
}

// Quick actions
function openJupyter() {
    window.open('http://localhost:8888', '_blank');
}

function openComfyUI() {
    window.open('http://localhost:8080', '_blank');
}

function openVSCode() {
    // This would need VSCode API integration
    alert('Open the project in VSCode to access this feature');
}

async function restartServices() {
    if (confirm('Restart all services? This may take a moment.')) {
        // This would need backend implementation
        alert('Service restart not yet implemented');
    }
}

// Load projects on page load
loadProjects();