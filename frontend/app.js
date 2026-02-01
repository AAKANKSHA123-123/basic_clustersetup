// Configuration - Use /api path (nginx will proxy to backend-service)
// For local development, change this to 'http://localhost:5000'
const API_URL = '/api';

// Check backend connection
async function checkHealth() {
    try {
        const response = await fetch(`${API_URL}/api/health`);
        const data = await response.json();
        updateStatus(true);
        return true;
    } catch (error) {
        console.error('Health check failed:', error);
        updateStatus(false);
        return false;
    }
}

function updateStatus(connected) {
    const statusEl = document.getElementById('status');
    if (connected) {
        statusEl.textContent = '✓ Connected to backend';
        statusEl.className = 'status-indicator connected';
    } else {
        statusEl.textContent = '✗ Backend connection failed';
        statusEl.className = 'status-indicator disconnected';
    }
}

// Load items from backend
async function loadItems() {
    try {
        const response = await fetch(`${API_URL}/api/items`);
        const data = await response.json();
        displayItems(data.items || []);
    } catch (error) {
        console.error('Failed to load items:', error);
        document.getElementById('itemsList').innerHTML = 
            '<div class="error">Failed to load items. Please check backend connection.</div>';
    }
}

// Display items in the UI
function displayItems(items) {
    const itemsList = document.getElementById('itemsList');
    
    if (items.length === 0) {
        itemsList.innerHTML = '<p class="empty">No items yet. Add one above!</p>';
        return;
    }
    
    itemsList.innerHTML = items.map(item => `
        <div class="item-card">
            <div class="item-info">
                <h3>${escapeHtml(item.name)}</h3>
                ${item.description ? `<p>${escapeHtml(item.description)}</p>` : ''}
            </div>
            <button class="delete-btn" onclick="deleteItem(${item.id})">Delete</button>
        </div>
    `).join('');
}

// Add new item
async function addItem(event) {
    event.preventDefault();
    
    const name = document.getElementById('itemName').value.trim();
    const description = document.getElementById('itemDescription').value.trim();
    
    if (!name) {
        alert('Please enter an item name');
        return;
    }
    
    try {
        const response = await fetch(`${API_URL}/api/items`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ name, description }),
        });
        
        if (response.ok) {
            document.getElementById('itemForm').reset();
            loadItems();
        } else {
            const error = await response.json();
            alert(`Error: ${error.error || 'Failed to add item'}`);
        }
    } catch (error) {
        console.error('Failed to add item:', error);
        alert('Failed to add item. Please check backend connection.');
    }
}

// Delete item
async function deleteItem(itemId) {
    if (!confirm('Are you sure you want to delete this item?')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_URL}/api/items/${itemId}`, {
            method: 'DELETE',
        });
        
        if (response.ok) {
            loadItems();
        } else {
            alert('Failed to delete item');
        }
    } catch (error) {
        console.error('Failed to delete item:', error);
        alert('Failed to delete item. Please check backend connection.');
    }
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('itemForm').addEventListener('submit', addItem);
    checkHealth();
    loadItems();
    
    // Refresh items every 5 seconds
    setInterval(loadItems, 5000);
});
