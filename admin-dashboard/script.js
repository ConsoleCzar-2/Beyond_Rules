/**
 * Beyond Rules — Admin Dashboard
 * Static mock with optional live API connection.
 * 
 * Configuration:
 *   To connect to the live FastAPI server, enter the server URL 
 *   (e.g. http://localhost:8000) in the sidebar input and click connect.
 */

// ===========================
// Configuration
// ===========================
const CONFIG = {
    apiUrl: '',          // Set via UI or hardcode for development
    useMockData: true,   // Falls back to mock when API is unreachable
    refreshInterval: 30000, // 30s auto-refresh when live
};

// ===========================
// Mock Data
// ===========================
const MOCK_DATA = {
    stats: {
        total_transaction_volume: 1245680.50,
        successful_transactions: 847,
        pending_admin_reviews: 5,
        overall_fraud_rate: 2.34,
    },

    pendingTransactions: [
        { id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', customer_id: 'C1234', merchant_id: 'M348934600', merch_category: 'es_transportation', amount: 32500.00, fraud_probability: 0.72, status: 'pending', timestamp: '2026-08-10T14:23:00' },
        { id: 'b2c3d4e5-f6a7-8901-bcde-f12345678901', customer_id: 'C5678', merchant_id: 'M129847300', merch_category: 'es_food_dining', amount: 18750.00, fraud_probability: 0.58, status: 'pending', timestamp: '2026-08-10T13:45:00' },
        { id: 'c3d4e5f6-a7b8-9012-cdef-123456789012', customer_id: 'C9012', merchant_id: 'M567890100', merch_category: 'es_health', amount: 45000.00, fraud_probability: 0.81, status: 'pending', timestamp: '2026-08-10T13:12:00' },
        { id: 'd4e5f6a7-b8c9-0123-defa-234567890123', customer_id: 'C3456', merchant_id: 'M234567800', merch_category: 'es_tech', amount: 67800.00, fraud_probability: 0.65, status: 'pending', timestamp: '2026-08-10T12:58:00' },
        { id: 'e5f6a7b8-c9d0-1234-efab-345678901234', customer_id: 'C7890', merchant_id: 'M890123400', merch_category: 'es_transportation', amount: 12300.00, fraud_probability: 0.44, status: 'pending', timestamp: '2026-08-10T12:30:00' },
    ],

    transactionLogs: [
        { id: 'f6a7b8c9-d0e1-2345-fabc-456789012345', customer_id: 'C1234', merchant_id: 'M111222333', merch_category: 'es_food_dining', amount: 850.00, fraud_probability: 0.08, status: 'paid', timestamp: '2026-08-10T14:50:00' },
        { id: 'a7b8c9d0-e1f2-3456-abcd-567890123456', customer_id: 'C5678', merchant_id: 'M444555666', merch_category: 'es_transportation', amount: 2200.00, fraud_probability: 0.12, status: 'paid', timestamp: '2026-08-10T14:35:00' },
        { id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', customer_id: 'C1234', merchant_id: 'M348934600', merch_category: 'es_transportation', amount: 32500.00, fraud_probability: 0.72, status: 'pending', timestamp: '2026-08-10T14:23:00' },
        { id: 'b8c9d0e1-f2a3-4567-bcde-678901234567', customer_id: 'C2345', merchant_id: 'M777888999', merch_category: 'es_health', amount: 5600.00, fraud_probability: 0.15, status: 'paid', timestamp: '2026-08-10T14:10:00' },
        { id: 'c9d0e1f2-a3b4-5678-cdef-789012345678', customer_id: 'C6789', merchant_id: 'M000111222', merch_category: 'es_tech', amount: 89000.00, fraud_probability: 0.91, status: 'fraud', timestamp: '2026-08-10T13:55:00' },
        { id: 'b2c3d4e5-f6a7-8901-bcde-f12345678901', customer_id: 'C5678', merchant_id: 'M129847300', merch_category: 'es_food_dining', amount: 18750.00, fraud_probability: 0.58, status: 'pending', timestamp: '2026-08-10T13:45:00' },
        { id: 'd0e1f2a3-b4c5-6789-defa-890123456789', customer_id: 'C0123', merchant_id: 'M333444555', merch_category: 'es_food_dining', amount: 1200.00, fraud_probability: 0.05, status: 'paid', timestamp: '2026-08-10T13:30:00' },
        { id: 'c3d4e5f6-a7b8-9012-cdef-123456789012', customer_id: 'C9012', merchant_id: 'M567890100', merch_category: 'es_health', amount: 45000.00, fraud_probability: 0.81, status: 'pending', timestamp: '2026-08-10T13:12:00' },
        { id: 'e1f2a3b4-c5d6-7890-efab-901234567890', customer_id: 'C4567', merchant_id: 'M666777888', merch_category: 'es_transportation', amount: 3400.00, fraud_probability: 0.22, status: 'paid', timestamp: '2026-08-10T13:00:00' },
        { id: 'd4e5f6a7-b8c9-0123-defa-234567890123', customer_id: 'C3456', merchant_id: 'M234567800', merch_category: 'es_tech', amount: 67800.00, fraud_probability: 0.65, status: 'pending', timestamp: '2026-08-10T12:58:00' },
        { id: 'f2a3b4c5-d6e7-8901-fabc-012345678901', customer_id: 'C8901', merchant_id: 'M999000111', merch_category: 'es_health', amount: 15000.00, fraud_probability: 0.35, status: 'paid', timestamp: '2026-08-10T12:45:00' },
        { id: 'e5f6a7b8-c9d0-1234-efab-345678901234', customer_id: 'C7890', merchant_id: 'M890123400', merch_category: 'es_transportation', amount: 12300.00, fraud_probability: 0.44, status: 'pending', timestamp: '2026-08-10T12:30:00' },
        { id: 'a3b4c5d6-e7f8-9012-abcd-123456789abc', customer_id: 'C2345', merchant_id: 'M222333444', merch_category: 'es_food_dining', amount: 780.00, fraud_probability: 0.03, status: 'paid', timestamp: '2026-08-10T12:15:00' },
        { id: 'b4c5d6e7-f8a9-0123-bcde-23456789abcd', customer_id: 'C6789', merchant_id: 'M555666777', merch_category: 'es_tech', amount: 42000.00, fraud_probability: 0.88, status: 'fraud', timestamp: '2026-08-10T11:50:00' },
        { id: 'c5d6e7f8-a9b0-1234-cdef-3456789abcde', customer_id: 'C0123', merchant_id: 'M888999000', merch_category: 'es_transportation', amount: 1800.00, fraud_probability: 0.11, status: 'paid', timestamp: '2026-08-10T11:30:00' },
        { id: 'd6e7f8a9-b0c1-2345-defa-456789abcdef', customer_id: 'C4567', merchant_id: 'M111222333', merch_category: 'es_food_dining', amount: 950.00, fraud_probability: 0.07, status: 'cancelled', timestamp: '2026-08-10T11:10:00' },
    ],

    trendData: {
        labels: ['Aug 1', 'Aug 2', 'Aug 3', 'Aug 4', 'Aug 5', 'Aug 6', 'Aug 7', 'Aug 8', 'Aug 9', 'Aug 10'],
        legitimate: [82, 91, 78, 95, 88, 92, 85, 97, 90, 84],
        flagged: [3, 5, 2, 4, 6, 3, 7, 4, 5, 5],
        fraud: [1, 2, 0, 1, 2, 1, 3, 1, 2, 2],
    },

    categoryFraud: {
        labels: ['Transportation', 'Food & Dining', 'Health', 'Technology', 'Leisure', 'Other'],
        counts: [12, 8, 6, 15, 3, 4],
    },

    scoreDistribution: {
        labels: ['0.0-0.1', '0.1-0.2', '0.2-0.3', '0.3-0.4', '0.4-0.5', '0.5-0.6', '0.6-0.7', '0.7-0.8', '0.8-0.9', '0.9-1.0'],
        counts: [320, 185, 98, 52, 34, 22, 15, 10, 8, 5],
    },

    hourlyVolume: {
        labels: Array.from({ length: 24 }, (_, i) => `${i}:00`),
        counts: [5, 2, 1, 1, 2, 8, 22, 45, 68, 72, 65, 58, 70, 62, 55, 48, 52, 60, 55, 42, 35, 28, 18, 10],
    },
};

// ===========================
// State
// ===========================
let currentSection = 'dashboard';
let chartInstances = {};

// ===========================
// Initialization
// ===========================
document.addEventListener('DOMContentLoaded', () => {
    initNavigation();
    initTimestamp();
    initConnection();
    loadDashboard();
});

// ===========================
// Navigation
// ===========================
function initNavigation() {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const section = item.dataset.section;
            if (section) navigateTo(section);
        });
    });

    document.querySelectorAll('.view-all').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const goto = link.dataset.goto;
            if (goto) navigateTo(goto);
        });
    });

    // Mobile menu toggle
    const menuToggle = document.getElementById('menuToggle');
    const sidebar = document.getElementById('sidebar');
    if (menuToggle) {
        menuToggle.addEventListener('click', () => {
            sidebar.classList.toggle('open');
        });
    }

    // Status filter
    const statusFilter = document.getElementById('statusFilter');
    if (statusFilter) {
        statusFilter.addEventListener('change', () => renderLogs());
    }
}

function navigateTo(section) {
    currentSection = section;

    // Update nav active state
    document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
    document.querySelector(`.nav-item[data-section="${section}"]`)?.classList.add('active');

    // Show section
    document.querySelectorAll('.content-section').forEach(s => s.classList.remove('active'));
    document.getElementById(`section-${section}`)?.classList.add('active');

    // Update header title
    const titles = { dashboard: 'Dashboard', pending: 'Pending Reviews', logs: 'Transaction Logs', analytics: 'Analytics' };
    document.getElementById('pageTitle').textContent = titles[section] || 'Dashboard';

    // Load section-specific data
    if (section === 'pending') renderPendingTable();
    if (section === 'logs') renderLogs();
    if (section === 'analytics') renderAnalyticsCharts();

    // Close mobile sidebar
    document.getElementById('sidebar')?.classList.remove('open');
}

// ===========================
// Timestamp
// ===========================
function initTimestamp() {
    const el = document.getElementById('timestamp');
    function update() {
        el.textContent = new Date().toLocaleString('en-IN', {
            day: '2-digit', month: 'short', year: 'numeric',
            hour: '2-digit', minute: '2-digit', second: '2-digit',
        });
    }
    update();
    setInterval(update, 1000);
}

// ===========================
// Live API Connection
// ===========================
function initConnection() {
    const btnConnect = document.getElementById('btnConnect');
    btnConnect.addEventListener('click', async () => {
        const url = document.getElementById('apiUrl').value.trim();
        if (!url) {
            showToast('Please enter an API URL', 'error');
            return;
        }
        CONFIG.apiUrl = url.replace(/\/$/, '');
        try {
            const res = await fetch(`${CONFIG.apiUrl}/health`, { signal: AbortSignal.timeout(5000) });
            if (res.ok) {
                CONFIG.useMockData = false;
                updateConnectionStatus(true);
                showToast('Connected to live API!', 'success');
                loadDashboard();
            } else {
                throw new Error('Health check failed');
            }
        } catch (err) {
            CONFIG.useMockData = true;
            updateConnectionStatus(false);
            showToast('Could not connect. Using mock data.', 'error');
        }
    });
}

function updateConnectionStatus(online) {
    const statusEl = document.getElementById('connectionStatus');
    const dot = statusEl.querySelector('.status-dot');
    const label = statusEl.querySelector('span:last-child');
    dot.className = `status-dot ${online ? 'online' : 'offline'}`;
    label.textContent = online ? 'Live' : 'Mock Mode';
}

// ===========================
// Data Fetching
// ===========================
async function fetchData(endpoint) {
    if (CONFIG.useMockData) return null;
    try {
        const res = await fetch(`${CONFIG.apiUrl}${endpoint}`, { signal: AbortSignal.timeout(5000) });
        if (res.ok) return await res.json();
    } catch (err) {
        console.warn(`API call failed for ${endpoint}:`, err);
    }
    return null;
}

// ===========================
// Dashboard
// ===========================
async function loadDashboard() {
    await loadStats();
    renderRecentFlagged();
    renderTrendChart();
    renderCategoryChart();
}

async function loadStats() {
    const liveStats = await fetchData('/admin/stats');
    const stats = liveStats || MOCK_DATA.stats;

    document.getElementById('statVolume').textContent = '₹' + formatNumber(stats.total_transaction_volume);
    document.getElementById('statSuccessful').textContent = formatNumber(stats.successful_transactions);
    document.getElementById('statPending').textContent = stats.pending_admin_reviews;
    document.getElementById('statFraudRate').textContent = stats.overall_fraud_rate.toFixed(2) + '%';
    document.getElementById('pendingBadge').textContent = stats.pending_admin_reviews;
}

function renderRecentFlagged() {
    const body = document.getElementById('recentFlaggedBody');
    const pending = MOCK_DATA.pendingTransactions.slice(0, 5);
    body.innerHTML = pending.map(tx => `
        <tr>
            <td><code>${tx.id.slice(0, 8)}…</code></td>
            <td>${tx.customer_id}</td>
            <td>${tx.merchant_id}</td>
            <td>₹${formatNumber(tx.amount)}</td>
            <td class="score-cell ${getScoreClass(tx.fraud_probability)}">${(tx.fraud_probability * 100).toFixed(1)}%</td>
            <td><span class="status-badge ${tx.status}">${formatStatus(tx.status)}</span></td>
        </tr>
    `).join('');
}

// ===========================
// Pending Reviews
// ===========================
async function renderPendingTable() {
    const livePending = await fetchData('/admin/pending_transactions');
    const pending = livePending || MOCK_DATA.pendingTransactions;

    const body = document.getElementById('pendingBody');
    body.innerHTML = pending.map(tx => `
        <tr data-id="${tx.id}">
            <td><code>${tx.id.slice(0, 8)}…</code></td>
            <td>${tx.customer_id}</td>
            <td>${tx.merchant_id}</td>
            <td>${formatCategory(tx.merch_category)}</td>
            <td>₹${formatNumber(tx.amount)}</td>
            <td class="score-cell ${getScoreClass(tx.fraud_probability)}">${(tx.fraud_probability * 100).toFixed(1)}%</td>
            <td>${formatTime(tx.timestamp)}</td>
            <td>
                <div class="action-btns">
                    <button class="btn-action approve" onclick="reviewTransaction('${tx.id}', 'approve')">✓ Approve</button>
                    <button class="btn-action reject" onclick="reviewTransaction('${tx.id}', 'reject')">✗ Reject</button>
                </div>
            </td>
        </tr>
    `).join('');
}

async function reviewTransaction(id, action) {
    if (!CONFIG.useMockData) {
        try {
            const res = await fetch(`${CONFIG.apiUrl}/admin/review_transaction`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id, action }),
            });
            if (res.ok) {
                showToast(`Transaction ${action === 'approve' ? 'approved' : 'rejected'} successfully!`, 'success');
                renderPendingTable();
                loadStats();
                return;
            }
        } catch (err) {
            console.warn('Live review failed, using mock:', err);
        }
    }

    // Mock: remove from table with animation
    const row = document.querySelector(`tr[data-id="${id}"]`);
    if (row) {
        row.style.opacity = '0';
        row.style.transform = 'translateX(40px)';
        row.style.transition = 'all 0.3s ease';
        setTimeout(() => {
            row.remove();
            // Update pending count
            const badge = document.getElementById('pendingBadge');
            const statPending = document.getElementById('statPending');
            const current = parseInt(badge.textContent) - 1;
            badge.textContent = Math.max(0, current);
            statPending.textContent = Math.max(0, current);
        }, 300);
    }

    const verb = action === 'approve' ? 'approved' : 'rejected as fraud';
    showToast(`Transaction ${id.slice(0, 8)}… ${verb}`, action === 'approve' ? 'success' : 'info');
}

// ===========================
// Transaction Logs
// ===========================
function renderLogs() {
    const filter = document.getElementById('statusFilter').value;
    let logs = [...MOCK_DATA.transactionLogs];
    if (filter !== 'all') {
        logs = logs.filter(tx => tx.status === filter);
    }

    const body = document.getElementById('logsBody');
    body.innerHTML = logs.map(tx => `
        <tr>
            <td><code>${tx.id.slice(0, 8)}…</code></td>
            <td>${tx.customer_id}</td>
            <td>${tx.merchant_id}</td>
            <td>${formatCategory(tx.merch_category)}</td>
            <td>₹${formatNumber(tx.amount)}</td>
            <td class="score-cell ${getScoreClass(tx.fraud_probability)}">${(tx.fraud_probability * 100).toFixed(1)}%</td>
            <td><span class="status-badge ${tx.status}">${formatStatus(tx.status)}</span></td>
            <td>${formatTime(tx.timestamp)}</td>
        </tr>
    `).join('');
}

// ===========================
// Charts
// ===========================
const CHART_COLORS = {
    blue: 'rgba(59, 76, 202, 1)',
    blueAlpha: 'rgba(59, 76, 202, 0.15)',
    purple: 'rgba(139, 92, 246, 1)',
    purpleAlpha: 'rgba(139, 92, 246, 0.15)',
    green: 'rgba(34, 197, 94, 1)',
    greenAlpha: 'rgba(34, 197, 94, 0.15)',
    red: 'rgba(239, 68, 68, 1)',
    redAlpha: 'rgba(239, 68, 68, 0.15)',
    orange: 'rgba(245, 158, 11, 1)',
    orangeAlpha: 'rgba(245, 158, 11, 0.15)',
    gold: 'rgba(255, 215, 0, 1)',
    gridColor: 'rgba(255, 255, 255, 0.05)',
    textColor: '#94a3b8',
};

const CHART_DEFAULTS = {
    responsive: true,
    maintainAspectRatio: true,
    plugins: {
        legend: { labels: { color: CHART_COLORS.textColor, font: { family: 'Inter', size: 12 }, padding: 16, usePointStyle: true, pointStyle: 'circle' } },
    },
    scales: {
        x: { ticks: { color: CHART_COLORS.textColor, font: { size: 11 } }, grid: { color: CHART_COLORS.gridColor } },
        y: { ticks: { color: CHART_COLORS.textColor, font: { size: 11 } }, grid: { color: CHART_COLORS.gridColor } },
    },
};

function destroyChart(id) {
    if (chartInstances[id]) {
        chartInstances[id].destroy();
        delete chartInstances[id];
    }
}

function renderTrendChart() {
    const id = 'trendChart';
    destroyChart(id);
    const ctx = document.getElementById(id).getContext('2d');
    const d = MOCK_DATA.trendData;

    chartInstances[id] = new Chart(ctx, {
        type: 'line',
        data: {
            labels: d.labels,
            datasets: [
                { label: 'Legitimate', data: d.legitimate, borderColor: CHART_COLORS.green, backgroundColor: CHART_COLORS.greenAlpha, fill: true, tension: 0.4, pointRadius: 3, pointHoverRadius: 6 },
                { label: 'Flagged', data: d.flagged, borderColor: CHART_COLORS.orange, backgroundColor: CHART_COLORS.orangeAlpha, fill: true, tension: 0.4, pointRadius: 3, pointHoverRadius: 6 },
                { label: 'Confirmed Fraud', data: d.fraud, borderColor: CHART_COLORS.red, backgroundColor: CHART_COLORS.redAlpha, fill: true, tension: 0.4, pointRadius: 3, pointHoverRadius: 6 },
            ],
        },
        options: { ...CHART_DEFAULTS, interaction: { intersect: false, mode: 'index' } },
    });
}

function renderCategoryChart() {
    const id = 'categoryChart';
    destroyChart(id);
    const ctx = document.getElementById(id).getContext('2d');
    const d = MOCK_DATA.categoryFraud;

    chartInstances[id] = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: d.labels,
            datasets: [{
                data: d.counts,
                backgroundColor: [CHART_COLORS.blue, CHART_COLORS.green, CHART_COLORS.purple, CHART_COLORS.red, CHART_COLORS.orange, CHART_COLORS.gold],
                borderColor: 'rgba(0,0,0,0.3)',
                borderWidth: 2,
                hoverOffset: 8,
            }],
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: { position: 'bottom', labels: { color: CHART_COLORS.textColor, font: { family: 'Inter', size: 11 }, padding: 12, usePointStyle: true } },
            },
            cutout: '60%',
        },
    });
}

function renderAnalyticsCharts() {
    // Score Distribution
    const sdId = 'scoreDistChart';
    destroyChart(sdId);
    const sdCtx = document.getElementById(sdId).getContext('2d');
    const sd = MOCK_DATA.scoreDistribution;
    chartInstances[sdId] = new Chart(sdCtx, {
        type: 'bar',
        data: {
            labels: sd.labels,
            datasets: [{
                label: 'Transactions',
                data: sd.counts,
                backgroundColor: sd.labels.map((_, i) => {
                    const frac = i / (sd.labels.length - 1);
                    return `rgba(${Math.round(34 + frac * 205)}, ${Math.round(197 - frac * 129)}, ${Math.round(94 - frac * 26)}, 0.8)`;
                }),
                borderRadius: 6,
                borderSkipped: false,
            }],
        },
        options: { ...CHART_DEFAULTS, plugins: { ...CHART_DEFAULTS.plugins, legend: { display: false } } },
    });

    // Hourly Volume
    const hvId = 'hourlyChart';
    destroyChart(hvId);
    const hvCtx = document.getElementById(hvId).getContext('2d');
    const hv = MOCK_DATA.hourlyVolume;
    chartInstances[hvId] = new Chart(hvCtx, {
        type: 'bar',
        data: {
            labels: hv.labels,
            datasets: [{
                label: 'Transactions',
                data: hv.counts,
                backgroundColor: CHART_COLORS.blueAlpha,
                borderColor: CHART_COLORS.blue,
                borderWidth: 1,
                borderRadius: 4,
                borderSkipped: false,
            }],
        },
        options: { ...CHART_DEFAULTS, plugins: { ...CHART_DEFAULTS.plugins, legend: { display: false } } },
    });

    // Model Comparison
    const mcId = 'modelCompareChart';
    destroyChart(mcId);
    const mcCtx = document.getElementById(mcId).getContext('2d');
    const labels = MOCK_DATA.trendData.labels;
    const gnnScores = [0.82, 0.78, 0.85, 0.91, 0.87, 0.83, 0.89, 0.92, 0.86, 0.88];
    const behavScores = [0.74, 0.71, 0.79, 0.85, 0.80, 0.76, 0.82, 0.88, 0.81, 0.83];
    const fusionScores = gnnScores.map((g, i) => +((g + behavScores[i]) / 2).toFixed(2));
    chartInstances[mcId] = new Chart(mcCtx, {
        type: 'line',
        data: {
            labels,
            datasets: [
                { label: 'GNN Score', data: gnnScores, borderColor: CHART_COLORS.blue, backgroundColor: CHART_COLORS.blueAlpha, fill: false, tension: 0.4, pointRadius: 4, borderWidth: 2 },
                { label: 'Behavioral Score', data: behavScores, borderColor: CHART_COLORS.purple, backgroundColor: CHART_COLORS.purpleAlpha, fill: false, tension: 0.4, pointRadius: 4, borderWidth: 2 },
                { label: 'Fusion Score', data: fusionScores, borderColor: CHART_COLORS.gold, backgroundColor: 'rgba(255, 215, 0, 0.1)', fill: true, tension: 0.4, pointRadius: 5, borderWidth: 3, borderDash: [5, 5] },
            ],
        },
        options: { ...CHART_DEFAULTS, interaction: { intersect: false, mode: 'index' }, scales: { ...CHART_DEFAULTS.scales, y: { ...CHART_DEFAULTS.scales.y, min: 0.5, max: 1.0 } } },
    });
}

// ===========================
// Toast Notifications
// ===========================
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    const icons = { success: '✓', error: '✗', info: 'ℹ' };
    toast.innerHTML = `<span>${icons[type] || 'ℹ'}</span> ${message}`;
    container.appendChild(toast);
    setTimeout(() => {
        toast.style.animation = 'slideOut 0.3s ease forwards';
        setTimeout(() => toast.remove(), 300);
    }, 3500);
}

// ===========================
// Utilities
// ===========================
function formatNumber(n) {
    return Number(n).toLocaleString('en-IN', { maximumFractionDigits: 0 });
}

function formatTime(ts) {
    return new Date(ts).toLocaleString('en-IN', {
        day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit',
    });
}

function formatStatus(s) {
    const map = { paid: 'Paid', pending: 'Pending', fraud: 'Fraud', cancelled: 'Cancelled', 'awaiting-user-confirmation': 'Awaiting User' };
    return map[s] || s;
}

function formatCategory(cat) {
    if (!cat) return '—';
    return cat.replace(/^es_/, '').replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

function getScoreClass(prob) {
    if (prob >= 0.7) return 'high';
    if (prob >= 0.4) return 'medium';
    return 'low';
}
