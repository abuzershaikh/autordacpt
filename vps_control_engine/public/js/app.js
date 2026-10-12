// ========================================================
// Ride AutoAccept VPS Control Engine — Dashboard Client JS
// ========================================================

const state = {
  token: localStorage.getItem('autoride_admin_token') || '',
  activeTab: 'overview',
  ridersPage: 1,
  ridesPage: 1,
  crashesPage: 1,
};

// --- DOM Elements ---
const loginOverlay = document.getElementById('loginOverlay');
const loginForm = document.getElementById('loginForm');
const loginError = document.getElementById('loginError');
const logoutBtn = document.getElementById('logoutBtn');
const liveClock = document.getElementById('liveClock');
const pageTitle = document.getElementById('pageTitle');

// --- Helper Functions ---
function getAuthHeaders() {
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${state.token}`,
  };
}

async function apiRequest(endpoint, options = {}) {
  const url = endpoint.startsWith('http') ? endpoint : `/api/admin${endpoint}`;
  const headers = { ...getAuthHeaders(), ...(options.headers || {}) };
  
  try {
    const res = await fetch(url, { ...options, headers });
    if (res.status === 401) {
      handleUnauthorized();
      throw new Error('Unauthorized');
    }
    return await res.json();
  } catch (err) {
    console.error(`API Error on ${url}:`, err);
    throw err;
  }
}

function handleUnauthorized() {
  state.token = '';
  localStorage.removeItem('autoride_admin_token');
  loginOverlay.classList.remove('hidden');
}

function formatDate(dateStr) {
  if (!dateStr) return '--';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-IN', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit'
  });
}

function updateClock() {
  const now = new Date();
  liveClock.textContent = now.toLocaleTimeString('en-IN', { hour12: false }) + ' IST';
}
setInterval(updateClock, 1000);
updateClock();

// --- Auth Handling ---
if (state.token) {
  loginOverlay.classList.add('hidden');
  initDashboard();
} else {
  loginOverlay.classList.remove('hidden');
}

loginForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  loginError.classList.add('hidden');

  const username = document.getElementById('loginUsername').value.trim();
  const password = document.getElementById('loginPassword').value.trim();

  try {
    const res = await fetch('/api/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    });

    const data = await res.json();
    if (data.success && data.token) {
      state.token = data.token;
      localStorage.setItem('autoride_admin_token', data.token);
      loginOverlay.classList.add('hidden');
      initDashboard();
    } else {
      loginError.textContent = data.error || 'Invalid credentials';
      loginError.classList.remove('hidden');
    }
  } catch (err) {
    loginError.textContent = 'Server connection failed';
    loginError.classList.remove('hidden');
  }
});

logoutBtn.addEventListener('click', () => {
  handleUnauthorized();
});

// --- Tab Navigation ---
document.querySelectorAll('.sidebar-nav .nav-item').forEach(button => {
  button.addEventListener('click', () => {
    document.querySelectorAll('.sidebar-nav .nav-item').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.view-panel').forEach(p => p.classList.remove('active'));

    button.classList.add('active');
    const tabName = button.dataset.tab;
    state.activeTab = tabName;

    const panel = document.getElementById(`tab-${tabName}`);
    if (panel) panel.classList.add('active');

    const titles = {
      overview: 'Live Overview',
      riders: 'Riders Directory & Profiles',
      rides: 'Live Ride Telemetry Streams',
      crashes: 'Crashlytics Exception Explorer',
      tutorials: 'YouTube Tutorials Studio',
      settings: 'Remote App Configuration',
      'version-control': 'APK Version Control & Fleet Upgrade Center'
    };
    pageTitle.textContent = titles[tabName] || 'Dashboard';

    loadActiveTabData();
  });
});

function loadActiveTabData() {
  switch (state.activeTab) {
    case 'overview': loadOverview(); break;
    case 'riders': loadRiders(); break;
    case 'rides': loadRides(); break;
    case 'crashes': loadCrashes(); break;
    case 'tutorials': loadTutorials(); break;
    case 'settings': loadSettings(); break;
    case 'version-control': loadVersions(); break;
  }
}

function initDashboard() {
  loadOverview();
  // Auto refresh overview every 25 seconds
  setInterval(() => {
    if (state.activeTab === 'overview' && state.token) {
      loadOverview();
    }
  }, 25000);
}

document.getElementById('btnRefreshData').addEventListener('click', () => {
  loadActiveTabData();
});

// --- 1. Overview Tab Data ---
async function loadOverview() {
  try {
    const res = await apiRequest('/overview');
    if (!res.success) return;

    const { riders, rides, platforms, crashes } = res.data;

    document.getElementById('kpiTotalRiders').textContent = riders.total || 0;
    document.getElementById('kpiOnlineRiders').textContent = `${riders.online || 0} Online`;
    document.getElementById('kpiAcceptedRides').textContent = rides.accepted || 0;
    document.getElementById('kpiAcceptanceRate').textContent = `${rides.acceptanceRate}% acceptance rate`;
    document.getElementById('kpiMissedRides').textContent = `${rides.missed || 0} / ${rides.filtered || 0}`;
    document.getElementById('kpiTotalFare').textContent = `₹${rides.totalAcceptedFare} earned`;
    document.getElementById('kpiActivePlans').textContent = riders.activePlans || 0;
    document.getElementById('kpiAccessibilityOn').textContent = `${riders.accessibilityActive || 0} Accessibility Active`;
    document.getElementById('kpiTotalCrashes').textContent = crashes.total || 0;
    document.getElementById('kpiUnresolvedCrashes').textContent = `${crashes.unresolved || 0} Unresolved`;
    document.getElementById('kpiAvgResponse').textContent = `${rides.avgResponseTimeMs || 0} ms`;

    // Render platform breakdown table
    const tbody = document.getElementById('platformBreakdownTbody');
    if (platforms && platforms.length > 0) {
      tbody.innerHTML = platforms.map(p => {
        const total = parseInt(p.total, 10) || 0;
        const accepted = parseInt(p.accepted, 10) || 0;
        const rate = total > 0 ? ((accepted / total) * 100).toFixed(1) : '0.0';
        return `
          <tr>
            <td><strong style="text-transform: capitalize;">${p.service}</strong></td>
            <td>${total}</td>
            <td class="text-green font-bold">${accepted}</td>
            <td class="text-amber">${p.missed}</td>
            <td><span class="badge badge-green">${rate}%</span></td>
          </tr>
        `;
      }).join('');
    } else {
      tbody.innerHTML = `
        <tr><td><strong>Porter</strong></td><td>0</td><td>0</td><td>0</td><td>0%</td></tr>
        <tr><td><strong>Rapido</strong></td><td>0</td><td>0</td><td>0</td><td>0%</td></tr>
        <tr><td><strong>Ola</strong></td><td>0</td><td>0</td><td>0</td><td>0%</td></tr>
        <tr><td><strong>Uber</strong></td><td>0</td><td>0</td><td>0</td><td>0%</td></tr>
      `;
    }
  } catch (err) {
    console.error('Failed to load overview:', err);
  }
}

// Quick Free Limit Button on Overview
document.getElementById('btnSaveQuickLimit').addEventListener('click', async () => {
  const limit = parseInt(document.getElementById('quickFreeLimitInput').value, 10);
  try {
    await apiRequest('/config', {
      method: 'PUT',
      body: JSON.stringify({ free_rides_limit: limit }),
    });
    alert(`✓ Dynamic Free Rides Limit updated to ${limit}! All drivers will sync this count.`);
  } catch (err) {
    alert('Failed to update limit');
  }
});

// Quick Announcement Button
document.getElementById('btnSaveQuickAnnouncement').addEventListener('click', async () => {
  const text = document.getElementById('quickAnnouncementInput').value.trim();
  try {
    await apiRequest('/config', {
      method: 'PUT',
      body: JSON.stringify({ announcement_text: text, announcement_active: 1 }),
    });
    alert('✓ Announcement broadcasted successfully!');
  } catch (err) {
    alert('Failed to broadcast announcement');
  }
});

// Sync Firestore Users Button
document.getElementById('btnSyncFirestore').addEventListener('click', async () => {
  const btn = document.getElementById('btnSyncFirestore');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Syncing...';

  try {
    const res = await apiRequest('/users/sync-firestore', {
      method: 'POST',
      body: JSON.stringify({ limit: 100 }),
    });
    alert(`✓ Synced ${res.synced || 0} user profiles from Cloud Firestore!`);
    loadActiveTabData();
  } catch (err) {
    alert('Firestore sync failed: ' + err.message);
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-cloud-arrow-down"></i> <span>Sync Firestore Users</span>';
  }
});

// --- 2. Riders Directory Tab ---
async function loadRiders() {
  const search = document.getElementById('riderSearchInput').value.trim();
  const planStatus = document.getElementById('riderPlanFilter').value;
  const tbody = document.getElementById('ridersTbody');
  tbody.innerHTML = '<tr><td colspan="9" class="text-center">Loading riders...</td></tr>';

  try {
    const res = await apiRequest(`/users?page=${state.ridersPage}&limit=12&search=${encodeURIComponent(search)}&planStatus=${planStatus}`);
    if (!res.success) return;

    const { data, pagination } = res;
    document.getElementById('ridersPaginationInfo').textContent = `Showing ${data.length} of ${pagination.total} riders`;
    document.getElementById('ridersPageNumber').textContent = `Page ${pagination.page} of ${pagination.totalPages || 1}`;
    document.getElementById('btnPrevRiders').disabled = pagination.page <= 1;
    document.getElementById('btnNextRiders').disabled = pagination.page >= pagination.totalPages;

    if (data.length === 0) {
      tbody.innerHTML = '<tr><td colspan="9" class="text-center text-muted">No riders found matching query.</td></tr>';
      return;
    }

    tbody.innerHTML = data.map(u => {
      const isOnline = u.is_online ? '<span class="badge badge-green">Online</span>' : '<span class="badge" style="background: rgba(255,255,255,0.06); color:#94A3B8;">Offline</span>';
      const a11yBadge = u.is_accessibility_enabled ? '<span class="badge badge-green"><i class="fa-solid fa-circle-check"></i> Enabled</span>' : '<span class="badge badge-red"><i class="fa-solid fa-circle-xmark"></i> Disabled</span>';
      const planBadge = u.plan_status === 'active' ? `<span class="badge badge-green">${u.plan_name}</span>` : `<span class="badge badge-amber">${u.plan_name || 'Free Trial'}</span>`;

      return `
        <tr>
          <td>
            <strong style="font-size:1.05rem;">${u.display_name || 'Driver Partner'}</strong>
            ${u.email ? `<br><small style="color: #60a5fa; font-weight: 500;"><i class="fa-solid fa-envelope"></i> ${u.email}</small>` : ''}
            <br><small class="text-dim font-mono" style="font-size:0.75rem;">UID: ${u.id.substring(0, 16)}...</small>
          </td>
          <td class="font-mono font-bold" style="color: #38bdf8;">${u.phone || '--'}</td>
          <td>${u.device_brand} ${u.device_model}<br><small class="text-dim">Android ${u.android_version}</small></td>
          <td>${planBadge}</td>
          <td>${a11yBadge}</td>
          <td>${isOnline}</td>
          <td>
            <span class="text-green font-bold">${u.today_accepted || 0}</span> / 
            <span class="text-amber">${u.today_missed || 0}</span>
          </td>
          <td><small>${formatDate(u.joined_at)}</small></td>
          <td>
            <button class="btn btn-secondary btn-sm" onclick="viewRiderDetail('${u.id}')">
              <i class="fa-solid fa-eye"></i> Dossier
            </button>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    tbody.innerHTML = '<tr><td colspan="9" class="text-center text-red">Failed to load riders list.</td></tr>';
  }
}

document.getElementById('btnSearchRiders').addEventListener('click', () => {
  state.ridersPage = 1;
  loadRiders();
});

document.getElementById('btnPrevRiders').addEventListener('click', () => {
  if (state.ridersPage > 1) {
    state.ridersPage--;
    loadRiders();
  }
});

document.getElementById('btnNextRiders').addEventListener('click', () => {
  state.ridersPage++;
  loadRiders();
});

// --- Dedicated Full-Screen Rider Deep Inspection View ---
let currentInspectedRiderId = null;

window.viewRiderDetail = async function(id) {
  currentInspectedRiderId = id;

  // Hide all other views
  document.querySelectorAll('.view-panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.sidebar-nav .nav-item').forEach(b => b.classList.remove('active'));

  // Show dedicated inspection screen
  const detailPanel = document.getElementById('tab-rider-detail');
  if (detailPanel) detailPanel.classList.add('active');

  pageTitle.textContent = 'Rider Deep Inspection & Diagnostics';

  await loadRiderDeepInspection(id);
};

async function loadRiderDeepInspection(id) {
  try {
    const res = await apiRequest(`/users/${id}`);
    if (!res.success) return;

    const { profile, rideSummary, missedRides, acceptedRides, recentCrashes } = res.data;

    // 1. Header & Hero Profile
    const dName = profile.display_name || 'Driver Partner';
    document.getElementById('rdBreadcrumbName').textContent = dName;
    document.getElementById('rdDisplayName').textContent = dName;
    document.getElementById('rdPhone').textContent = profile.phone || '--';
    document.getElementById('rdEmail').textContent = profile.email || 'No email registered';
    document.getElementById('rdUid').textContent = profile.id;
    document.getElementById('rdDeviceSpecs').textContent = `${profile.device_brand || 'Android'} ${profile.device_model || ''} (Android ${profile.android_version || '14+'})`;
    document.getElementById('rdJoinedAt').textContent = formatDate(profile.joined_at);
    document.getElementById('rdLastPing').textContent = profile.last_ping_at ? formatDate(profile.last_ping_at) : 'No ping received';

    // Status Badges
    const onlineBadge = document.getElementById('rdOnlineBadge');
    if (profile.is_online) {
      onlineBadge.className = 'badge badge-green';
      onlineBadge.innerHTML = '<i class="fa-solid fa-circle" style="font-size: 8px;"></i> Online';
    } else {
      onlineBadge.className = 'badge';
      onlineBadge.style.cssText = 'background: rgba(255,255,255,0.06); color:#94A3B8;';
      onlineBadge.innerHTML = '<i class="fa-solid fa-circle" style="font-size: 8px;"></i> Offline';
    }

    const a11yBadge = document.getElementById('rdA11yBadge');
    if (profile.is_accessibility_enabled) {
      a11yBadge.className = 'badge badge-green';
      a11yBadge.innerHTML = '<i class="fa-solid fa-check"></i> Accessibility Active';
    } else {
      a11yBadge.className = 'badge badge-red';
      a11yBadge.innerHTML = '<i class="fa-solid fa-xmark"></i> Accessibility Disabled';
    }

    const planPill = document.getElementById('rdPlanPill');
    planPill.className = `badge ${profile.plan_status === 'active' ? 'badge-green' : 'badge-purple'}`;
    planPill.textContent = profile.plan_name || 'Free Trial';

    // 2. Card 1: Rider Configured Limits
    const autoAcceptVal = document.getElementById('rdAutoAcceptVal');
    autoAcceptVal.innerHTML = profile.auto_accept_enabled !== 0 
      ? '<span class="badge badge-green">ENABLED</span>' 
      : '<span class="badge badge-red">DISABLED</span>';
    document.getElementById('rdMinFareVal').textContent = `₹${parseFloat(profile.min_fare || 40).toFixed(0)}`;
    document.getElementById('rdMaxFareVal').textContent = `₹${parseFloat(profile.max_fare || 2000).toFixed(0)}`;
    document.getElementById('rdMaxPickupVal').textContent = `${parseFloat(profile.max_pickup_distance || 5.0).toFixed(1)} km`;
    document.getElementById('rdMaxTripVal').textContent = `${parseFloat(profile.max_trip_distance || 30.0).toFixed(1)} km`;
    document.getElementById('rdClickSpeedVal').textContent = profile.click_speed || 'Instant (5ms)';

    // 3. Card 2: Plan & Free Trial
    document.getElementById('rdSubPlanName').textContent = profile.plan_name || 'Free Trial';
    const subStatusVal = document.getElementById('rdSubStatusVal');
    subStatusVal.innerHTML = `<span class="badge ${profile.plan_status === 'active' ? 'badge-green' : 'badge-amber'}">${(profile.plan_status || 'inactive').toUpperCase()}</span>`;
    document.getElementById('rdPlanExpiresVal').textContent = profile.plan_expires_at ? formatDate(profile.plan_expires_at) : 'No expiration date';

    const freeLimit = parseInt(profile.free_rides_limit || 2, 10);
    const freeUsed = parseInt(profile.free_rides_used || 0, 10);
    document.getElementById('rdFreeUsedVal').textContent = `${freeUsed} / ${freeLimit} used`;

    const trialStatusVal = document.getElementById('rdTrialStatusVal');
    const trialWarnBox = document.getElementById('rdTrialWarningBox');
    if (profile.plan_status === 'active') {
      trialStatusVal.innerHTML = '<span class="badge badge-green">PAID SUBSCRIBER</span>';
      trialWarnBox.innerHTML = '<i class="fa-solid fa-circle-check text-green"></i> Paid active subscriber. Free ride restrictions bypassed.';
    } else if (freeUsed >= freeLimit) {
      trialStatusVal.innerHTML = '<span class="badge badge-red">TRIAL EXHAUSTED</span>';
      trialWarnBox.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-red"></i> <strong>Trial Exhausted!</strong> Auto-accept blocked. Driver must purchase 1-Day or Weekly plan.';
    } else {
      const left = freeLimit - freeUsed;
      trialStatusVal.innerHTML = `<span class="badge badge-green">${left} FREE RIDES REMAINING</span>`;
      trialWarnBox.innerHTML = `<i class="fa-solid fa-gift text-cyan"></i> ${left} free rides left before subscription prompt is triggered.`;
    }

    // 4. Card 3: Platform Performance Mini Breakdown
    const miniList = document.getElementById('rdPlatformMiniList');
    if (rideSummary && rideSummary.length > 0) {
      miniList.innerHTML = rideSummary.map(s => `
        <div class="mini-p-row">
          <span class="mini-p-badge"><i class="fa-solid fa-taxi text-dim"></i> ${s.service}</span>
          <div class="mini-p-stats">
            <span class="text-green font-bold">${s.accepted_count} acc</span>
            <span class="text-amber">${s.missed_count} miss</span>
            <span>₹${parseFloat(s.total_fare || 0).toFixed(0)}</span>
          </div>
        </div>
      `).join('');
    } else {
      miniList.innerHTML = '<div class="text-dim text-center" style="font-size: 11.5px; padding: 10px 0;">No ride telemetry events detected yet.</div>';
    }

    // 5. Card 4: Forensic Diagnostic Advice & Driver Mistakes
    const diagBox = document.getElementById('rdDiagnosticAdvices');
    const advices = [];

    if (!profile.is_accessibility_enabled) {
      advices.push(`
        <div class="diag-advice-item danger">
          <i class="fa-solid fa-triangle-exclamation"></i>
          <div><strong>Accessibility Disabled:</strong> Android killed the accessibility service on this device. Auto-accept cannot tap orders until driver re-enables it in Accessibility settings.</div>
        </div>
      `);
    }

    if (profile.plan_status !== 'active' && freeUsed >= freeLimit) {
      advices.push(`
        <div class="diag-advice-item danger">
          <i class="fa-solid fa-ban"></i>
          <div><strong>Trial Exhausted (${freeUsed}/${freeLimit} used):</strong> Driver has no active plan and all trial rides are exhausted. All incoming orders will be blocked until a plan is purchased!</div>
        </div>
      `);
    }

    if (profile.auto_accept_enabled === 0) {
      advices.push(`
        <div class="diag-advice-item danger">
          <i class="fa-solid fa-toggle-off"></i>
          <div><strong>Auto-Accept Toggle is OFF:</strong> Driver turned off the auto-accept master toggle inside the app.</div>
        </div>
      `);
    }

    // Check missed rides for patterns
    if (missedRides && missedRides.length > 0) {
      const lowFareRides = missedRides.filter(r => (r.reason && r.reason.toLowerCase().includes('fare')) || (r.user_min_fare > 0 && r.fare < r.user_min_fare));
      if (lowFareRides.length > 0) {
        advices.push(`
          <div class="diag-advice-item warning">
            <i class="fa-solid fa-money-bill-wave"></i>
            <div><strong>Min Fare Too High:</strong> ${lowFareRides.length} orders were missed because the fare was below driver's min limit (₹${profile.min_fare}). Tell driver to lower min fare to ₹30-40.</div>
          </div>
        `);
      }

      const longTripRides = missedRides.filter(r => (r.reason && r.reason.toLowerCase().includes('trip')) || (r.user_max_trip > 0 && r.trip_distance > r.user_max_trip));
      if (longTripRides.length > 0) {
        advices.push(`
          <div class="diag-advice-item warning">
            <i class="fa-solid fa-route"></i>
            <div><strong>Max Trip Distance Reached:</strong> ${longTripRides.length} orders exceeded max trip distance (${profile.max_trip_distance}km). Tell driver to increase trip distance limit.</div>
          </div>
        `);
      }
    }

    if (advices.length === 0) {
      advices.push(`
        <div class="diag-advice-item success">
          <i class="fa-solid fa-circle-check"></i>
          <div><strong>All Systems Optimal:</strong> Driver settings, accessibility, and trial/plan status are fully operational!</div>
        </div>
      `);
    }
    diagBox.innerHTML = advices.join('');

    // 6. Table 1: Missed & Filtered Rides Forensic Audit Table
    const missedTbody = document.getElementById('rdMissedRidesTbody');
    const missedCountBadge = document.getElementById('rdMissedCountBadge');
    missedCountBadge.textContent = `${(missedRides || []).length} Missed`;

    if (missedRides && missedRides.length > 0) {
      missedTbody.innerHTML = missedRides.map(r => {
        const minFareLimit = r.user_min_fare > 0 ? r.user_min_fare : profile.min_fare;
        const maxTripLimit = r.user_max_trip > 0 ? r.user_max_trip : profile.max_trip_distance;
        const maxPickupLimit = r.user_max_pickup > 0 ? r.user_max_pickup : profile.max_pickup_distance;

        let fareHtml = `<strong>₹${parseFloat(r.fare).toFixed(0)}</strong>`;
        if (minFareLimit && r.fare > 0 && r.fare < minFareLimit) {
          fareHtml += ` <span class="tag-pill tag-danger"><i class="fa-solid fa-arrow-down"></i> Below Min ₹${minFareLimit}</span>`;
        }

        let tripHtml = `${parseFloat(r.trip_distance).toFixed(1)} km`;
        if (maxTripLimit && r.trip_distance > maxTripLimit) {
          tripHtml += ` <span class="tag-pill tag-warning"><i class="fa-solid fa-arrow-up"></i> Exceeds ${maxTripLimit}km</span>`;
        }

        let pickupHtml = `${parseFloat(r.pickup_distance).toFixed(1)} km`;
        if (maxPickupLimit && r.pickup_distance > maxPickupLimit) {
          pickupHtml += ` <span class="tag-pill tag-warning">Exceeds ${maxPickupLimit}km</span>`;
        }

        let failureDetail = r.reason || 'Filtered out by rider preferences or timeout';

        return `
          <tr>
            <td><small>${formatDate(r.created_at)}</small></td>
            <td><strong style="text-transform: capitalize;">${r.service}</strong></td>
            <td>${fareHtml}</td>
            <td>${tripHtml}</td>
            <td>${pickupHtml}</td>
            <td><span class="text-amber font-bold">${failureDetail}</span></td>
            <td><span class="badge badge-amber">${r.status.toUpperCase()}</span></td>
          </tr>
        `;
      }).join('');
    } else {
      missedTbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">No missed or filtered rides recorded for this driver.</td></tr>';
    }

    // 7. Table 2: Accepted Rides Stream Table
    const acceptedTbody = document.getElementById('rdAcceptedRidesTbody');
    const acceptedCountBadge = document.getElementById('rdAcceptedCountBadge');
    acceptedCountBadge.textContent = `${(acceptedRides || []).length} Accepted`;

    if (acceptedRides && acceptedRides.length > 0) {
      acceptedTbody.innerHTML = acceptedRides.map(r => `
        <tr>
          <td><small>${formatDate(r.created_at)}</small></td>
          <td><strong style="text-transform: capitalize;">${r.service}</strong></td>
          <td class="text-green font-bold">₹${parseFloat(r.fare).toFixed(0)}</td>
          <td>${parseFloat(r.pickup_distance).toFixed(1)} km</td>
          <td>${parseFloat(r.trip_distance).toFixed(1)} km</td>
          <td><span class="badge badge-cyan font-mono">${r.response_time_ms}ms</span></td>
          <td><small class="font-mono text-dim">${r.order_id || '--'}</small></td>
        </tr>
      `).join('');
    } else {
      acceptedTbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">No accepted rides recorded yet.</td></tr>';
    }

    // 8. Table 3: Crashes Table
    const crashTbody = document.getElementById('rdCrashesTbody');
    const crashCountBadge = document.getElementById('rdCrashCountBadge');
    crashCountBadge.textContent = `${(recentCrashes || []).length} Crashes`;

    if (recentCrashes && recentCrashes.length > 0) {
      crashTbody.innerHTML = recentCrashes.map(c => `
        <tr>
          <td><small>${formatDate(c.created_at)}</small></td>
          <td><span class="badge badge-cyan">${c.screen_name || 'AppRoot'}</span></td>
          <td><div class="code-block error-block" style="padding: 4px 8px; font-size: 11px;">${(c.error_message || '').substring(0, 100)}...</div></td>
          <td><span class="badge ${c.is_resolved ? 'badge-green' : 'badge-red'}">${c.is_resolved ? 'Resolved' : 'Unresolved'}</span></td>
        </tr>
      `).join('');
    } else {
      crashTbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted">Zero crashes recorded on this device.</td></tr>';
    }

  } catch (err) {
    console.error('Error loading rider deep inspection:', err);
    alert('Failed to load rider inspection details: ' + err.message);
  }
}

// Back to Riders Directory Button
document.getElementById('btnBackToRiders').addEventListener('click', () => {
  document.querySelectorAll('.view-panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.sidebar-nav .nav-item').forEach(b => b.classList.remove('active'));

  const ridersPanel = document.getElementById('tab-riders');
  if (ridersPanel) ridersPanel.classList.add('active');

  const ridersBtn = document.querySelector('.sidebar-nav .nav-item[data-tab="riders"]');
  if (ridersBtn) ridersBtn.classList.add('active');

  state.activeTab = 'riders';
  pageTitle.textContent = 'Riders Directory & Profiles';
  loadRiders();
});

// Refresh button on rider screen
document.getElementById('btnRefreshRiderScreen').addEventListener('click', () => {
  if (currentInspectedRiderId) {
    loadRiderDeepInspection(currentInspectedRiderId);
  }
});

// --- 3. Ride Streams Tab ---
async function loadRides() {
  const search = document.getElementById('rideSearchInput').value.trim();
  const service = document.getElementById('rideServiceFilter').value;
  const status = document.getElementById('rideStatusFilter').value;
  const tbody = document.getElementById('ridesTbody');
  tbody.innerHTML = '<tr><td colspan="10" class="text-center">Loading ride events...</td></tr>';

  try {
    const res = await apiRequest(`/rides?page=${state.ridesPage}&limit=15&service=${service}&status=${status}&search=${encodeURIComponent(search)}`);
    if (!res.success) return;

    const { data, pagination } = res;
    document.getElementById('ridesPaginationInfo').textContent = `Showing ${data.length} of ${pagination.total} rides`;
    document.getElementById('ridesPageNumber').textContent = `Page ${pagination.page} of ${pagination.totalPages || 1}`;
    document.getElementById('btnPrevRides').disabled = pagination.page <= 1;
    document.getElementById('btnNextRides').disabled = pagination.page >= pagination.totalPages;

    if (data.length === 0) {
      tbody.innerHTML = '<tr><td colspan="10" class="text-center text-muted">No rides recorded yet.</td></tr>';
      return;
    }

    tbody.innerHTML = data.map(r => {
      let statusBadge = `<span class="badge badge-amber">${r.status}</span>`;
      if (r.status === 'accepted') statusBadge = `<span class="badge badge-green"><i class="fa-solid fa-check"></i> Accepted</span>`;
      if (r.status === 'missed') statusBadge = `<span class="badge badge-red"><i class="fa-solid fa-xmark"></i> Missed</span>`;

      return `
        <tr>
          <td class="font-mono">#${r.id}</td>
          <td>
            <strong>${r.driver_name || 'Driver'}</strong>
            <br><small class="text-dim font-mono">${r.driver_phone || '--'}</small>
          </td>
          <td><strong style="text-transform: capitalize;">${r.service}</strong></td>
          <td>${statusBadge}</td>
          <td class="font-bold">₹${parseFloat(r.fare).toFixed(0)}</td>
          <td>${r.pickup_distance} km</td>
          <td>${r.trip_distance} km</td>
          <td><span class="badge badge-cyan font-mono">${r.response_time_ms}ms</span></td>
          <td><small class="text-dim">${r.reason || '--'}</small></td>
          <td><small>${formatDate(r.created_at)}</small></td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    tbody.innerHTML = '<tr><td colspan="10" class="text-center text-red">Failed to load rides.</td></tr>';
  }
}

document.getElementById('btnFilterRides').addEventListener('click', () => {
  state.ridesPage = 1;
  loadRides();
});

document.getElementById('btnPrevRides').addEventListener('click', () => {
  if (state.ridesPage > 1) {
    state.ridesPage--;
    loadRides();
  }
});

document.getElementById('btnNextRides').addEventListener('click', () => {
  state.ridesPage++;
  loadRides();
});

// --- 4. Crashlytics Tab ---
async function loadCrashes() {
  const search = document.getElementById('crashSearchInput').value.trim();
  const isResolved = document.getElementById('crashStatusFilter').value;
  const tbody = document.getElementById('crashesTbody');
  tbody.innerHTML = '<tr><td colspan="9" class="text-center">Loading crash reports...</td></tr>';

  try {
    const res = await apiRequest(`/crashes?page=${state.crashesPage}&limit=12&isResolved=${isResolved}&search=${encodeURIComponent(search)}`);
    if (!res.success) return;

    const { data, pagination } = res;
    document.getElementById('crashesPaginationInfo').textContent = `Showing ${data.length} of ${pagination.total} crashes`;
    document.getElementById('crashesPageNumber').textContent = `Page ${pagination.page} of ${pagination.totalPages || 1}`;
    document.getElementById('btnPrevCrashes').disabled = pagination.page <= 1;
    document.getElementById('btnNextCrashes').disabled = pagination.page >= pagination.totalPages;

    if (data.length === 0) {
      tbody.innerHTML = '<tr><td colspan="9" class="text-center text-muted">Zero crashes recorded! System running stable.</td></tr>';
      return;
    }

    tbody.innerHTML = data.map(c => {
      const resolvedBadge = c.is_resolved 
        ? '<span class="badge badge-green"><i class="fa-solid fa-check"></i> Resolved</span>'
        : '<span class="badge badge-red"><i class="fa-solid fa-triangle-exclamation"></i> Open</span>';

      return `
        <tr>
          <td class="font-mono">#${c.id}</td>
          <td>
            <div style="max-width: 260px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-weight: 600;">
              ${c.error_message}
            </div>
          </td>
          <td><small class="badge badge-blue">${c.screen_name || 'Background'}</small></td>
          <td>${c.device_brand || ''} ${c.device_model || ''}<br><small class="text-dim">Android ${c.os_version || '--'}</small></td>
          <td class="font-mono">${c.driver_phone || 'Anonymous'}</td>
          <td><small class="badge badge-purple">v${c.app_version}</small></td>
          <td><small>${formatDate(c.created_at)}</small></td>
          <td>${resolvedBadge}</td>
          <td>
            <div style="display: flex; gap: 6px;">
              <button class="btn btn-secondary btn-sm" onclick="viewCrashTrace('${encodeURIComponent(c.error_message)}', '${encodeURIComponent(c.stack_trace || 'No stack trace captured')}', '${c.screen_name || ''}')">
                Trace
              </button>
              <button class="btn btn-sm ${c.is_resolved ? 'btn-secondary' : 'btn-primary'}" onclick="toggleResolveCrash(${c.id}, ${!c.is_resolved})">
                ${c.is_resolved ? 'Reopen' : 'Resolve'}
              </button>
            </div>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    tbody.innerHTML = '<tr><td colspan="9" class="text-center text-red">Failed to load crashes.</td></tr>';
  }
}

window.viewCrashTrace = function(msg, trace, screen) {
  document.getElementById('modalCrashSubtitle').textContent = decodeURIComponent(screen) || 'App Crash';
  document.getElementById('modalCrashMessage').textContent = decodeURIComponent(msg);
  document.getElementById('modalCrashStack').textContent = decodeURIComponent(trace);
  document.getElementById('crashModal').classList.remove('hidden');
};

document.getElementById('modalCrashCloseBtn').addEventListener('click', () => {
  document.getElementById('crashModal').classList.add('hidden');
});

window.toggleResolveCrash = async function(id, newState) {
  try {
    await apiRequest(`/crashes/${id}/resolve`, {
      method: 'PATCH',
      body: JSON.stringify({ isResolved: newState }),
    });
    loadCrashes();
  } catch (err) {
    alert('Failed to update crash status');
  }
};

document.getElementById('btnFilterCrashes').addEventListener('click', () => {
  state.crashesPage = 1;
  loadCrashes();
});

// --- 5. Tutorials Studio Tab ---
async function loadTutorials() {
  const container = document.getElementById('tutorialsListContainer');
  container.innerHTML = '<div class="text-center text-muted">Loading tutorials...</div>';

  try {
    const res = await apiRequest('/tutorials');
    if (!res.success) return;

    const list = res.data || [];
    document.getElementById('tutCountBadge').textContent = `${list.length} Videos`;

    if (list.length === 0) {
      container.innerHTML = '<div class="text-center text-muted">No tutorials created yet. Add one on the left!</div>';
      return;
    }

    container.innerHTML = list.map(t => `
      <div class="tut-card">
        <img src="${t.thumbnail_url || 'https://img.youtube.com/vi/' + t.youtube_id + '/hqdefault.jpg'}" alt="Thumb" class="tut-thumb">
        <div class="tut-details">
          <div class="tut-title">${t.title}</div>
          <div style="display: flex; gap: 8px; align-items: center;">
            <span class="tut-cat-badge">${t.category}</span>
            <small class="text-dim">Order: #${t.order_index}</small>
            <a href="${t.youtube_url}" target="_blank" style="color: var(--primary); font-size: 11px;"><i class="fa-solid fa-arrow-up-right-from-square"></i> Open</a>
          </div>
        </div>
        <div class="tut-actions">
          <button class="btn btn-secondary btn-sm" onclick="editTutorial(${t.id}, '${encodeURIComponent(t.title)}', '${encodeURIComponent(t.youtube_url)}', '${t.category}', ${t.order_index}, '${encodeURIComponent(t.description || '')}')">
            <i class="fa-solid fa-pen"></i>
          </button>
          <button class="btn btn-logout btn-sm" onclick="deleteTutorial(${t.id})">
            <i class="fa-solid fa-trash"></i>
          </button>
        </div>
      </div>
    `).join('');
  } catch (err) {
    container.innerHTML = '<div class="text-center text-red">Failed to load tutorials.</div>';
  }
}

// Live YouTube URL input thumbnail preview
document.getElementById('tutUrl').addEventListener('input', (e) => {
  const url = e.target.value.trim();
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=|shorts\/)([^#&?]*).*/;
  const match = url.match(regExp);
  const ytId = match && match[2].length === 11 ? match[2] : '';

  const wrap = document.getElementById('ytPreviewWrap');
  if (ytId) {
    document.getElementById('ytPreviewThumb').src = `https://img.youtube.com/vi/${ytId}/hqdefault.jpg`;
    document.getElementById('ytPreviewId').textContent = ytId;
    wrap.classList.remove('hidden');
  } else {
    wrap.classList.add('hidden');
  }
});

// Tutorial Form Submit (Create or Update)
document.getElementById('tutorialForm').addEventListener('submit', async (e) => {
  e.preventDefault();

  const editId = document.getElementById('tutorialEditId').value;
  const title = document.getElementById('tutTitle').value.trim();
  const youtubeUrl = document.getElementById('tutUrl').value.trim();
  const category = document.getElementById('tutCategory').value;
  const orderIndex = parseInt(document.getElementById('tutOrder').value, 10) || 0;
  const description = document.getElementById('tutDescription').value.trim();

  const payload = { title, youtubeUrl, category, orderIndex, description };

  try {
    if (editId) {
      await apiRequest(`/tutorials/${editId}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      });
      alert('✓ Tutorial updated successfully!');
    } else {
      await apiRequest('/tutorials', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      alert('✓ New tutorial published live to mobile app!');
    }

    resetTutorialForm();
    loadTutorials();
  } catch (err) {
    alert('Failed to save tutorial: ' + err.message);
  }
});

window.editTutorial = function(id, title, url, category, order, desc) {
  document.getElementById('tutorialFormHeading').innerHTML = '<i class="fa-solid fa-pen-to-square"></i> Edit Tutorial Video';
  document.getElementById('tutorialEditId').value = id;
  document.getElementById('tutTitle').value = decodeURIComponent(title);
  document.getElementById('tutUrl').value = decodeURIComponent(url);
  document.getElementById('tutCategory').value = category;
  document.getElementById('tutOrder').value = order;
  document.getElementById('tutDescription').value = decodeURIComponent(desc);
  document.getElementById('btnCancelTutEdit').classList.remove('hidden');
  document.getElementById('btnSubmitTutText').textContent = 'Update Tutorial';

  // Trigger preview
  document.getElementById('tutUrl').dispatchEvent(new Event('input'));
};

function resetTutorialForm() {
  document.getElementById('tutorialFormHeading').innerHTML = '<i class="fa-solid fa-plus-circle"></i> Add New YouTube Tutorial Video';
  document.getElementById('tutorialEditId').value = '';
  document.getElementById('tutorialForm').reset();
  document.getElementById('ytPreviewWrap').classList.add('hidden');
  document.getElementById('btnCancelTutEdit').classList.add('hidden');
  document.getElementById('btnSubmitTutText').textContent = 'Save Tutorial to App';
}

document.getElementById('btnCancelTutEdit').addEventListener('click', resetTutorialForm);

window.deleteTutorial = async function(id) {
  if (!confirm('Are you sure you want to delete this tutorial video from app?')) return;
  try {
    await apiRequest(`/tutorials/${id}`, { method: 'DELETE' });
    loadTutorials();
  } catch (err) {
    alert('Failed to delete tutorial');
  }
};

// --- 6. Remote Settings Tab ---
async function loadSettings() {
  try {
    const res = await apiRequest('/config');
    if (!res.success) return;
    const s = res.settings || {};

    if (s.free_rides_limit) document.getElementById('settingFreeRides').value = s.free_rides_limit;
    if (s.min_app_version) document.getElementById('settingMinVersion').value = s.min_app_version;
    if (s.announcement_text) document.getElementById('settingAnnouncement').value = s.announcement_text;
    document.getElementById('settingAnnouncementActive').checked = s.announcement_active === '1';
  } catch (err) {
    console.error('Failed to load settings:', err);
  }
}

document.getElementById('settingsForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const limit = parseInt(document.getElementById('settingFreeRides').value, 10);
  const minVersion = document.getElementById('settingMinVersion').value.trim();
  const announcement = document.getElementById('settingAnnouncement').value.trim();
  const isActive = document.getElementById('settingAnnouncementActive').checked;

  try {
    await apiRequest('/config', {
      method: 'PUT',
      body: JSON.stringify({
        free_rides_limit: limit,
        min_app_version: minVersion,
        announcement_text: announcement,
        announcement_active: isActive ? 1 : 0,
      }),
    });
    alert('✓ Remote app configuration saved successfully!');
  } catch (err) {
    alert('Failed to save settings: ' + err.message);
  }
});

// --- 7. Version Control & Fleet Upgrade Center ---
async function loadVersions() {
  try {
    const res = await apiRequest('/versions');
    if (!res.success) return;

    const versions = res.versions || [];
    const cfg = res.config || {};

    // Update KPI counters
    const elLatestV = document.getElementById('vcKpiLatestVersion');
    const elLatestC = document.getElementById('vcKpiLatestCode');
    const elMinC = document.getElementById('vcKpiMinCode');
    const elForce = document.getElementById('vcKpiForceStatus');
    const elTotal = document.getElementById('vcKpiTotalVersions');

    if (elLatestV) elLatestV.textContent = 'v' + (cfg.latest_version_name || '1.0.0');
    if (elLatestC) elLatestC.textContent = 'Build Code: ' + (cfg.latest_version_code || 1);
    if (elMinC) elMinC.textContent = 'Code ' + (cfg.min_version_code || 1);
    if (elForce) {
      elForce.textContent = cfg.global_force_update ? 'Active 🚨' : 'Disabled';
      elForce.className = cfg.global_force_update ? 'metric-value text-red font-bold' : 'metric-value text-green';
    }
    if (elTotal) elTotal.textContent = versions.length;

    // Fill Global Policy Form
    const polMin = document.getElementById('vcPolicyMinCode');
    const polUrl = document.getElementById('vcPolicyDownloadUrl');
    const polMsg = document.getElementById('vcPolicyMessage');
    const polForce = document.getElementById('vcPolicyForceAll');

    if (polMin) polMin.value = cfg.min_version_code || 1;
    if (polUrl) polUrl.value = cfg.global_download_url || 'http://65.20.77.112:5000/download/latest.apk';
    if (polMsg) polMsg.value = cfg.global_update_message || '';
    if (polForce) polForce.checked = Boolean(cfg.global_force_update);

    // Render Versions Table
    const tbody = document.getElementById('versionFleetTbody');
    if (!tbody) return;

    if (versions.length === 0) {
      tbody.innerHTML = '<tr><td colspan="9" class="text-center text-dim">No versions registered yet. Publish a release above or connect mobile app.</td></tr>';
      return;
    }

    tbody.innerHTML = versions.map(v => {
      const isBlocked = Boolean(v.is_blocked);
      const isForced = Boolean(v.is_force_update);
      const isMinBlocked = v.version_code < (cfg.min_version_code || 1);
      const effectivelyBlocked = isBlocked || isMinBlocked;

      const statusBadge = effectivelyBlocked
        ? '<span class="badge badge-red font-bold"><i class="fa-solid fa-ban"></i> BLOCKED & DISABLED</span>'
        : '<span class="badge badge-green font-bold"><i class="fa-solid fa-circle-check"></i> ACTIVE & ALLOWED</span>';

      const forceBadge = isForced
        ? '<span class="badge badge-amber font-bold">YES (Mandatory)</span>'
        : '<span class="text-dim">Optional</span>';

      const dUrl = v.download_url || cfg.global_download_url || '#';
      const dLink = dUrl.startsWith('http')
        ? `<a href="${dUrl}" target="_blank" class="font-mono text-cyan" style="text-decoration:underline;" title="${dUrl}">${dUrl.length > 28 ? dUrl.slice(0, 25) + '...' : dUrl}</a>`
        : '<span class="text-dim">--</span>';

      return `
        <tr>
          <td><strong class="font-bold text-white">v${v.version_name}</strong></td>
          <td><span class="badge badge-purple font-mono">Code ${v.version_code}</span></td>
          <td>${statusBadge}</td>
          <td>${forceBadge}</td>
          <td><span class="font-bold font-mono text-green">${v.device_count || 0}</span> pings</td>
          <td>${dLink}</td>
          <td><small class="text-dim" title="${v.update_message || ''}">${(v.update_message || '--').slice(0, 32)}${(v.update_message || '').length > 32 ? '...' : ''}</small></td>
          <td><small class="text-dim">${formatDate(v.created_at)}</small></td>
          <td style="white-space:nowrap;">
            <button class="btn btn-sm ${isBlocked ? 'btn-success' : 'btn-danger'}" onclick="toggleVersionBlock(${v.id})" title="${isBlocked ? 'Unblock and allow this version' : 'Disable and force-block all users on this version'}">
              <i class="fa-solid ${isBlocked ? 'fa-unlock' : 'fa-ban'}"></i>
              <span>${isBlocked ? 'Enable' : 'Disable / Block'}</span>
            </button>
            <button class="btn btn-secondary btn-sm" onclick="deleteVersionRecord(${v.id})" title="Delete version record" style="margin-left: 4px;">
              <i class="fa-solid fa-trash text-red"></i>
            </button>
          </td>
        </tr>
      `;
    }).join('');

  } catch (err) {
    console.error('Failed to load version fleet:', err);
  }
}

// Global functions for inline action buttons
window.toggleVersionBlock = async (id) => {
  try {
    const res = await apiRequest(`/versions/${id}/toggle`, { method: 'PATCH' });
    if (res.success) {
      loadVersions();
    }
  } catch (err) {
    alert('Failed to toggle version status: ' + err.message);
  }
};

window.deleteVersionRecord = async (id) => {
  if (!confirm('Are you sure you want to delete this version entry from the database?')) return;
  try {
    const res = await apiRequest(`/versions/${id}`, { method: 'DELETE' });
    if (res.success) {
      loadVersions();
    }
  } catch (err) {
    alert('Failed to delete version record: ' + err.message);
  }
};

const btnRefreshVersions = document.getElementById('btnRefreshVersions');
if (btnRefreshVersions) {
  btnRefreshVersions.addEventListener('click', () => loadVersions());
}

// Publish New Release Form
const formNewRelease = document.getElementById('formNewRelease');
if (formNewRelease) {
  formNewRelease.addEventListener('submit', async (e) => {
    e.preventDefault();
    const versionName = document.getElementById('vcInputVersionName').value.trim();
    const versionCode = parseInt(document.getElementById('vcInputVersionCode').value, 10);
    const downloadUrl = document.getElementById('vcInputDownloadUrl').value.trim();
    const isForceUpdate = document.getElementById('vcInputForceUpdate').checked;
    const updateTitle = document.getElementById('vcInputTitle').value.trim();
    const updateMessage = document.getElementById('vcInputMessage').value.trim();
    const releaseNotes = document.getElementById('vcInputNotes').value.trim();

    try {
      const res = await apiRequest('/versions', {
        method: 'POST',
        body: JSON.stringify({
          versionName,
          versionCode,
          downloadUrl,
          isForceUpdate,
          updateTitle,
          updateMessage,
          releaseNotes
        }),
      });

      if (res.success) {
        alert(`✓ Release v${versionName} (Build ${versionCode}) published successfully!\nDrivers on older versions will see the update screen.`);
        loadVersions();
      }
    } catch (err) {
      alert('Failed to publish release: ' + err.message);
    }
  });
}

// Global Version Policy Form
const formGlobalVersionPolicy = document.getElementById('formGlobalVersionPolicy');
if (formGlobalVersionPolicy) {
  formGlobalVersionPolicy.addEventListener('submit', async (e) => {
    e.preventDefault();
    const minCode = parseInt(document.getElementById('vcPolicyMinCode').value, 10);
    const dUrl = document.getElementById('vcPolicyDownloadUrl').value.trim();
    const msg = document.getElementById('vcPolicyMessage').value.trim();
    const forceAll = document.getElementById('vcPolicyForceAll').checked;

    try {
      const res = await apiRequest('/versions/config', {
        method: 'POST',
        body: JSON.stringify({
          minSupportedCode: minCode,
          globalDownloadUrl: dUrl,
          globalUpdateMessage: msg,
          globalForceUpdate: forceAll,
        }),
      });

      if (res.success) {
        alert('✓ Global version policy and killswitch settings saved successfully!');
        loadVersions();
      }
    } catch (err) {
      alert('Failed to save global version policy: ' + err.message);
    }
  });
}
