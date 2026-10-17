#!/usr/bin/env bash
set -euo pipefail

PUBLIC_DIR="${1:-public}"
RUNTIME_MJS="${PUBLIC_DIR}/kof-runtime.mjs"
INDEX_HTML="${PUBLIC_DIR}/index.html"

if [ ! -f "$RUNTIME_MJS" ]; then
    echo "Erro: $RUNTIME_MJS nao encontrado." >&2
    exit 1
fi

# 1. Patch idempotente e nao-destrutivo em kof-runtime.mjs
if ! grep -q "XMLHttpRequest" "$RUNTIME_MJS"; then
    awk '
    /^function kofUiInjectTheme\(\) \{$/ {
        print
        print "    return;"
        next
    }
    /^export function kofUiWindowSetTheme\(window, theme\) \{$/ {
        print
        print "    if (typeof document !== \"undefined\" && document.documentElement && document.documentElement.setAttribute) {"
        print "        document.documentElement.setAttribute(\"data-theme\", theme ? \"dark\" : \"light\");"
        print "    }"
        print "    return;"
        next
    }
    /^    if \(n\) n\.id = id;$/ {
        print "    if (n) { n.id = id; if (typeof globalThis.__kofRegisterElement === \"function\") globalThis.__kofRegisterElement(id, n); }"
        next
    }
    /^    if \(n\) n\.classList\.add\(cls\);$/ {
        print "    if (n) { const base = String(n.className || \"\").split(/\\s+/).filter(c => c.startsWith(\"kof-\")).join(\" \"); n.className = (base ? base + \" \" : \"\") + String(cls || \"\").trim(); }"
        next
    }
    /^        return window\.__kofNodes\[sel\]\.selectedIndex;$/ {
        print "        const idx = window.__kofNodes[sel].selectedIndex; return idx >= 0 ? idx : 0;"
        next
    }
    /action\.invoke\(\);/ {
        print "            if (String(node.className || \"\").includes(\"tab-btn\") && node.parentNode) {"
        print "                const siblings = node.parentNode.children || [];"
        print "                for (const s of siblings) {"
        print "                    if (String(s.className || \"\").includes(\"tab-btn\")) {"
        print "                        s.className = \"kof-button tab-btn sidebar-link\";"
        print "                    }"
        print "                }"
        print "                node.className = \"kof-button tab-btn sidebar-link active\";"
        print "            }"
        print "            action.invoke();"
        next
    }
    /^                td\.textContent = String\(cell\);$/ {
        print "                const raw = String(cell);"
        print "                td.textContent = raw;"
        print "                if (typeof document !== \"undefined\" && typeof document.createElement === \"function\" && typeof window !== \"undefined\" && window.HTMLElement) {"
        print "                    const colIdx = tr.children.length;"
        print "                    const hName = (header && header[colIdx]) ? String(header[colIdx]).toUpperCase() : \"\";"
        print "                    if (raw === \"Estável\" || raw === \"Ativo\" || raw === \"Entrada\") {"
        print "                        td.innerHTML = `<span class=\"estocae-badge badge-green\">${raw}</span>`;"
        print "                    } else if (raw === \"Crítico\" || raw === \"Inativo\" || raw === \"Saída\") {"
        print "                        td.innerHTML = `<span class=\"estocae-badge badge-red\">${raw}</span>`;"
        print "                    } else if (raw === \"Atenção\") {"
        print "                        td.innerHTML = `<span class=\"estocae-badge badge-amber\">${raw}</span>`;"
        print "                    } else if (raw === \"Ajuste\") {"
        print "                        td.innerHTML = `<span class=\"estocae-badge badge-blue\">${raw}</span>`;"
        print "                    } else if (raw === \"Editar | Excluir\") {"
        print "                        td.innerHTML = `<span class=\"table-action-icons\"><span class=\"act-ico\" title=\"Editar\">✎</span><span class=\"act-ico danger\" title=\"Excluir\">🗑</span></span>`;"
        print "                    } else if (raw === \"Ver | Excluir\") {"
        print "                        td.innerHTML = `<span class=\"table-action-icons\"><span class=\"act-ico\" title=\"Visualizar\">👁</span><span class=\"act-ico danger\" title=\"Excluir\">🗑</span></span>`;"
        print "                    } else if (hName === \"QUANTIDADE\") {"
        print "                        const qCls = raw.startsWith(\"+\") ? \"qty-plus\" : (raw.startsWith(\"-\") ? \"qty-minus\" : \"qty-neutral\");"
        print "                        td.innerHTML = `<span class=\"${qCls}\">${raw}</span>`;"
        print "                    } else if (hName === \"ESTOQUE TOTAL\" && raw.includes(\"unidades\")) {"
        print "                        const num = parseInt(raw, 10) || 0;"
        print "                        const pct = Math.min(100, Math.max(8, Math.round((num / 60) * 100)));"
        print "                        const barCls = num <= 5 ? \"bar-red\" : (num <= 15 ? \"bar-amber\" : \"bar-green\");"
        print "                        td.innerHTML = `<div class=\"stock-progress-cell\"><span class=\"stock-qty-lbl\">${raw}</span><div class=\"stock-bar-track\"><div class=\"stock-bar-fill ${barCls}\" style=\"width:${pct}%\"></div></div></div>`;"
        print "                    } else if (colIdx === 0 && (hName.includes(\"PRODUTO\") || hName.includes(\"PASTO\"))) {"
        print "                        if (raw.includes(\"(#SKU\")) {"
        print "                            const parts = raw.split(\"(#SKU\");"
        print "                            const pTitle = parts[0].trim();"
        print "                            const pSku = \"#SKU\" + parts[1].replace(\")\", \"\");"
        print "                            const bgColors = [\"pastel-blue\", \"pastel-purple\", \"pastel-amber\", \"pastel-green\"];"
        print "                            const cCls = bgColors[tbody.children.length % 4];"
        print "                            td.innerHTML = `<div class=\"prod-cell\"><span class=\"prod-cube ${cCls}\">❖</span><div class=\"prod-meta\"><span class=\"prod-name\">${pTitle}</span><span class=\"prod-sku\">${pSku}</span></div></div>`;"
        print "                        } else {"
        print "                            td.innerHTML = `<div class=\"prod-cell\"><span class=\"prod-cube solid-orange\">❖</span><span class=\"prod-name\">${raw}</span></div>`;"
        print "                        }"
        print "                    }"
        print "                }"
        next
    }
    /if \(typeof fetch !== \x27undefined\x27\) \{/ {
        print "            if (typeof XMLHttpRequest !== \x27undefined\x27) {"
        print "                const xhr = new XMLHttpRequest();"
        print "                xhr.open(method, url, false);"
        print "                let hasCt = false;"
        print "                if (headers) {"
        print "                    const lines = headers.split(\"\\n\");"
        print "                    for (const line of lines) {"
        print "                        const i = line.indexOf(\":\");"
        print "                        if (i > 0) {"
        print "                            const hk = line.substring(0, i).trim();"
        print "                            const hv = line.substring(i + 1).trim();"
        print "                            xhr.setRequestHeader(hk, hv);"
        print "                            if (hk.toLowerCase() === \"content-type\") hasCt = true;"
        print "                        }"
        print "                    }"
        print "                }"
        print "                if (body != null && !hasCt) {"
        print "                    xhr.setRequestHeader(\"Content-Type\", \"application/json\");"
        print "                }"
        print "                xhr.send(body != null ? body : null);"
        print "                if (xhr.status >= 500) {"
        print "                    lastErr = new Error(\"HTTP \" + xhr.status + \" from \" + url);"
        print "                    kofHttpCircuitRecordFailure();"
        print "                    continue;"
        print "                }"
        print "                kofHttpCircuitRecordSuccess();"
        print "                return xhr.responseText != null ? xhr.responseText : \"\";"
        print "            }"
    }
    { print }
    ' "$RUNTIME_MJS" > "${RUNTIME_MJS}.tmp" && mv "${RUNTIME_MJS}.tmp" "$RUNTIME_MJS"
fi

# 2. Gerar index.html seguindo fielmente o Design System Estocaê (Figma)
cat > "$INDEX_HTML" << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR" data-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="service" content="kof-gado-api" data-ui="/ui">
  <title>Estocaê · AgroKOF — Controle de Estoque Inteligente</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root, html[data-theme="light"] {
      --bg-app: #f6f8fb;
      --bg-sidebar: #ffffff;
      --bg-card: #ffffff;
      --bg-input: #ffffff;
      --bg-muted: #f1f5f9;
      --border: #e5e7eb;
      --border-strong: #d1d5db;
      --fg: #111827;
      --fg-secondary: #374151;
      --fg-muted: #6b7280;
      --navy: #0f2942;
      --navy-hover: #163a5f;
      --orange: #f28c38;
      --orange-hover: #e07b27;
      --orange-soft: #fde8d7;
      --blue-active-bg: #eaf2ff;
      --blue: #2563eb;
      --green: #10b981;
      --red: #ef4444;
      --amber: #f59e0b;
      --purple: #9333ea;
      --card-shadow: 0 2px 10px rgba(15, 23, 42, 0.05), 0 1px 3px rgba(15, 23, 42, 0.04);
      --radius-sm: 8px;
      --radius-md: 12px;
      --radius-lg: 14px;
    }

    html[data-theme="dark"] {
      --bg-app: #0f172a;
      --bg-sidebar: #1e293b;
      --bg-card: #1e293b;
      --bg-input: #0f172a;
      --bg-muted: #334155;
      --border: #334155;
      --border-strong: #475569;
      --fg: #f8fafc;
      --fg-secondary: #cbd5e1;
      --fg-muted: #94a3b8;
      --navy: #f28c38;
      --navy-hover: #e07b27;
      --orange: #f28c38;
      --orange-hover: #fb923c;
      --orange-soft: rgba(242, 140, 56, 0.18);
      --blue-active-bg: rgba(37, 99, 235, 0.22);
      --card-shadow: 0 4px 20px rgba(0, 0, 0, 0.35);
    }

    * {
      box-sizing: border-box;
    }

    html, body {
      margin: 0;
      padding: 0;
      min-height: 100vh;
      background: var(--bg-app);
      color: var(--fg);
      font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      font-size: 14px;
      line-height: 1.45;
      -webkit-font-smoothing: antialiased;
      overflow-x: hidden;
    }

    #kof-root, .kof-window {
      width: 100% !important;
      min-height: 100vh !important;
      margin: 0 !important;
      padding: 0 !important;
      border: none !important;
      background: var(--bg-app) !important;
    }

    /* ======================================================================
       APP SHELL (SIDEBAR FIXA A ESQUERDA + AREA PRINCIPAL)
       ====================================================================== */
    .estocae-app-shell {
      display: flex !important;
      flex-direction: row !important;
      align-items: stretch !important;
      flex-wrap: nowrap !important;
      min-height: 100vh;
      width: 100%;
      gap: 0 !important;
    }

    .estocae-sidebar {
      width: 248px;
      min-width: 248px;
      max-width: 248px;
      background: var(--bg-sidebar);
      border-right: 1px solid var(--border);
      display: flex !important;
      flex-direction: column !important;
      justify-content: space-between;
      padding: 0 !important;
      gap: 0 !important;
      position: sticky;
      top: 0;
      height: 100vh;
      z-index: 20;
    }

    .estocae-sidebar-brand {
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      gap: 10px !important;
      padding: 18px 22px;
      border-bottom: 1px solid var(--border);
    }

    .estocae-logo-cube {
      width: 34px;
      height: 34px;
      border-radius: 8px;
      background: #0f2942;
      color: #ffffff !important;
      display: inline-flex !important;
      align-items: center;
      justify-content: center;
      font-size: 18px !important;
      font-weight: 700;
      box-shadow: 0 2px 6px rgba(15, 41, 66, 0.25);
    }

    .estocae-logo-text {
      color: var(--orange) !important;
      font-size: 23px !important;
      font-weight: 800 !important;
      letter-spacing: -0.02em;
    }

    .sidebar-nav-list {
      flex: 1;
      padding: 16px 14px !important;
      display: flex !important;
      flex-direction: column !important;
      gap: 4px !important;
      overflow-y: auto;
    }

    .sidebar-section-label {
      color: var(--fg-muted) !important;
      font-size: 11px !important;
      font-weight: 700 !important;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      padding: 10px 10px 6px !important;
    }

    .sidebar-link {
      width: 100%;
      justify-content: flex-start !important;
      text-align: left !important;
      background: transparent !important;
      border: none !important;
      border-radius: 9px !important;
      padding: 10px 14px !important;
      color: var(--fg-secondary) !important;
      font-size: 13.5px !important;
      font-weight: 500 !important;
      cursor: pointer;
      transition: background 0.15s ease, color 0.15s ease;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .sidebar-link:hover {
      background: var(--bg-muted) !important;
      color: var(--fg) !important;
    }

    .sidebar-link.active {
      background: var(--blue-active-bg) !important;
      color: #0f2942 !important;
      font-weight: 600 !important;
    }

    html[data-theme="dark"] .sidebar-link.active {
      color: #93c5fd !important;
    }

    .sidebar-user-footer {
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      gap: 12px !important;
      padding: 14px 18px;
      border-top: 1px solid var(--border);
    }

    .sidebar-user-avatar {
      width: 38px;
      height: 38px;
      border-radius: 50%;
      background: linear-gradient(135deg, #f28c38, #e11d48);
      color: #ffffff !important;
      font-weight: 700;
      font-size: 13px !important;
      display: inline-flex !important;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .sidebar-user-info {
      display: flex !important;
      flex-direction: column !important;
      gap: 1px !important;
      min-width: 0;
    }

    .sidebar-user-name {
      font-size: 13px !important;
      font-weight: 600 !important;
      color: var(--fg) !important;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .sidebar-user-role {
      font-size: 11.5px !important;
      color: var(--fg-muted) !important;
    }

    /* ======================================================================
       MAIN CONTENT AREA & TOPBAR
       ====================================================================== */
    .estocae-main-area {
      flex: 1;
      min-width: 0;
      display: flex !important;
      flex-direction: column !important;
      gap: 0 !important;
      background: var(--bg-app);
    }

    .estocae-topbar {
      background: var(--bg-sidebar);
      border-bottom: 1px solid var(--border);
      padding: 14px 28px;
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      justify-content: space-between !important;
      gap: 16px !important;
      position: sticky;
      top: 0;
      z-index: 15;
    }

    .topbar-page-title {
      color: var(--fg) !important;
      font-size: 16px !important;
      font-weight: 600 !important;
    }

    .topbar-right {
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      gap: 8px !important;
      flex-wrap: wrap;
    }

    .topbar-search-box {
      display: flex !important;
      flex-direction: row !important;
      flex-wrap: nowrap !important;
      align-items: center !important;
      gap: 8px !important;
      background: var(--bg-input);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 6px 12px;
      width: 260px;
      color: var(--fg-muted);
    }

    .topbar-search-input {
      border: none !important;
      background: transparent !important;
      padding: 2px 0 !important;
      font-size: 13px !important;
      color: var(--fg) !important;
      outline: none !important;
      box-shadow: none !important;
      flex: 1 1 auto !important;
      width: auto !important;
      min-width: 0 !important;
    }

    .btn-top-chip {
      background: var(--bg-input) !important;
      border: 1px solid var(--border) !important;
      color: var(--fg-secondary) !important;
      border-radius: 7px !important;
      padding: 6px 10px !important;
      font-size: 12px !important;
      font-weight: 600 !important;
      cursor: pointer;
    }

    .btn-top-chip:hover {
      background: var(--bg-muted) !important;
    }

    .btn-top-chip.primary-chip {
      background: var(--orange-soft) !important;
      border-color: rgba(242, 140, 56, 0.35) !important;
      color: var(--orange) !important;
    }

    .topbar-bell-btn {
      width: 34px;
      height: 34px;
      border-radius: 8px;
      display: inline-flex !important;
      align-items: center;
      justify-content: center;
      color: var(--fg-muted);
      cursor: pointer;
    }

    .status-banner {
      margin: 12px 28px 0;
      padding: 8px 14px;
      border-radius: 8px;
      background: #ffffff;
      border: 1px solid var(--border);
      color: var(--fg-muted) !important;
      font-size: 12px;
      display: block;
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.03);
    }

    html[data-theme="dark"] .status-banner {
      background: var(--bg-card);
    }

    /* ======================================================================
       VIEW SCREENS & CARDS
       ====================================================================== */
    .view-screen {
      padding: 20px 28px 40px;
      display: flex !important;
      flex-direction: column !important;
      gap: 20px !important;
      width: 100%;
    }

    .view-screen.hidden {
      display: none !important;
    }

    .estocae-card {
      background: var(--bg-card);
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      padding: 22px 24px;
      box-shadow: var(--card-shadow);
      display: flex !important;
      flex-direction: column !important;
      gap: 16px !important;
    }

    /* ======================================================================
       KPI CARDS (4 COLUMNS)
       ====================================================================== */
    .kpi-grid {
      display: grid !important;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 18px !important;
      width: 100%;
    }

    .estocae-kpi-card {
      background: var(--bg-card);
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      padding: 20px 22px;
      box-shadow: var(--card-shadow);
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      justify-content: space-between !important;
      flex-wrap: nowrap !important;
    }

    .kpi-left, .compact-kpi > .kof-column:first-child {
      display: flex !important;
      flex-direction: column !important;
      gap: 4px !important;
    }

    .kpi-title, .compact-kpi > .kof-column:first-child > .kof-label:first-child {
      color: var(--fg-muted) !important;
      font-size: 12.5px !important;
      font-weight: 500 !important;
    }

    .kpi-number {
      color: var(--fg) !important;
      font-size: 24px !important;
      font-weight: 800 !important;
      letter-spacing: -0.02em;
      line-height: 1.15;
    }

    .kpi-trend {
      font-size: 11.5px !important;
      font-weight: 600 !important;
      margin-top: 2px;
    }

    .kpi-trend.up { color: var(--green) !important; }
    .kpi-trend.down { color: var(--red) !important; }

    .kpi-icon-circle,
    .compact-kpi > .kof-column:last-child {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      display: inline-flex !important;
      align-items: center !important;
      justify-content: center !important;
      flex-shrink: 0;
    }

    .kpi-icon-circle.blue, .blue-kpi > .kof-column:last-child {
      background: #e0edff;
      color: #2563eb;
    }

    .kpi-icon-circle.red, .red-kpi > .kof-column:last-child {
      background: #fee2e2;
      color: #ef4444;
    }

    .kpi-icon-circle.green, .green-kpi > .kof-column:last-child {
      background: #dcfce7;
      color: #16a34a;
    }

    .kpi-icon-circle.purple {
      background: #f3e8ff;
      color: #9333ea;
    }

    .amber-kpi > .kof-column:last-child {
      background: #fef3c7;
      color: #d97706;
    }

    .kpi-currency-sym {
      color: #16a34a !important;
      font-size: 20px !important;
      font-weight: 700 !important;
    }

    /* ======================================================================
       DASHBOARD CHARTS & ACTIVITY GRIDS (TELA 1)
       ====================================================================== */
    .dash-charts-grid {
      display: grid !important;
      grid-template-columns: 2.15fr 1fr;
      gap: 20px !important;
      align-items: stretch !important;
      width: 100%;
    }

    .card-header-between {
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      justify-content: space-between !important;
      width: 100%;
    }

    .card-section-title {
      font-size: 15px !important;
      font-weight: 700 !important;
      color: var(--fg) !important;
    }

    .period-pills-row {
      display: flex !important;
      flex-direction: row !important;
      gap: 4px !important;
    }

    .period-pill {
      background: transparent !important;
      border: none !important;
      border-radius: 6px !important;
      padding: 5px 12px !important;
      font-size: 12px !important;
      font-weight: 600 !important;
      color: var(--fg-secondary) !important;
      cursor: pointer;
    }

    .period-pill.active {
      background: #e0edff !important;
      color: #2563eb !important;
    }

    .chart-legend-row {
      display: flex !important;
      flex-direction: row !important;
      justify-content: center !important;
      gap: 24px !important;
    }

    .chart-legend-item {
      font-size: 12px !important;
      font-weight: 500 !important;
      color: var(--fg-secondary) !important;
    }

    .chart-legend-item.blue { color: #2563eb !important; font-weight: 600 !important; }
    .chart-legend-item.green { color: #10b981 !important; font-weight: 600 !important; }

    .kof-canvas {
      width: 100%;
      max-width: 100%;
      height: auto;
      display: block;
      margin: 0 auto;
    }

    .chart-side-card .kof-canvas {
      max-width: 220px;
    }

    .donut-leg-row {
      display: grid !important;
      grid-template-columns: 1fr 1fr;
      gap: 8px !important;
      width: 100%;
    }

    .donut-leg {
      font-size: 11.5px !important;
      color: var(--fg-secondary) !important;
      font-weight: 500 !important;
    }

    .donut-leg.purple { color: #7c3aed !important; }
    .donut-leg.green { color: #059669 !important; }
    .donut-leg.orange { color: #d97706 !important; }
    .donut-leg.blue { color: #2563eb !important; }

    /* Bottom Grid: Recent Activities + Stock Status */
    .dash-bottom-grid {
      display: grid !important;
      grid-template-columns: 1fr 2.25fr;
      gap: 20px !important;
      align-items: stretch !important;
      width: 100%;
    }

    .activity-item {
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      gap: 14px !important;
      padding: 6px 0;
    }

    .activity-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      display: inline-flex !important;
      align-items: center !important;
      justify-content: center !important;
      flex-shrink: 0;
    }

    .activity-avatar.blue { background: #e0edff; color: #2563eb; }
    .activity-avatar.green { background: #dcfce7; color: #16a34a; }
    .activity-avatar.purple { background: #f3e8ff; color: #9333ea; }
    .activity-avatar.orange { background: #ffedd5; color: #ea580c; }

    .activity-text {
      display: flex !important;
      flex-direction: column !important;
      gap: 2px !important;
    }

    .activity-title {
      font-size: 13px !important;
      font-weight: 600 !important;
      color: var(--fg) !important;
    }

    .activity-sub {
      font-size: 11.5px !important;
      color: var(--fg-muted) !important;
    }

    .link-btn-blue {
      background: transparent !important;
      border: none !important;
      color: #2563eb !important;
      font-size: 12.5px !important;
      font-weight: 600 !important;
      cursor: pointer;
    }

    /* ======================================================================
       INVENTORY HEADER, FORMS & BUTTONS (TELA 2, 3, 4)
       ====================================================================== */
    .inventory-header-bar {
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      justify-content: space-between !important;
      gap: 16px !important;
      flex-wrap: wrap;
    }

    .inventory-title-col {
      display: flex !important;
      flex-direction: column !important;
      gap: 2px !important;
    }

    .inventory-title-col > .kof-label:first-child {
      font-size: 16px !important;
      font-weight: 700 !important;
      color: var(--fg) !important;
    }

    .inventory-title-col > .kof-label:last-child {
      font-size: 12.5px !important;
      color: var(--fg-muted) !important;
    }

    .inventory-actions-row {
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      gap: 10px !important;
      flex-wrap: nowrap !important;
    }

    .inventory-actions-row > .kof-select {
      width: auto !important;
      min-width: 145px;
    }

    .form-inline-card > .kof-label:first-child,
    .orange-section-heading {
      font-size: 15px !important;
      font-weight: 700 !important;
      color: var(--fg) !important;
      display: flex !important;
      align-items: center;
      gap: 8px;
    }

    .kof-row {
      display: flex;
      flex-direction: row;
      flex-wrap: wrap;
      gap: 14px;
      align-items: flex-end;
    }

    .field-group {
      display: flex !important;
      flex-direction: column !important;
      gap: 6px !important;
      flex: 0 0 auto;
      width: 100%;
      min-width: 0;
    }

    .kof-row > .field-group {
      flex: 1 1 180px;
      width: auto;
    }

    .field-label {
      color: var(--fg-secondary) !important;
      font-size: 12px !important;
      font-weight: 600 !important;
    }

    .kof-input, .kof-select, .kof-textarea {
      width: 100%;
      font-family: inherit;
      font-size: 13px;
      color: var(--fg);
      background: var(--bg-input);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 9px 12px;
      outline: none;
      transition: border-color 0.15s ease, box-shadow 0.15s ease;
    }

    .kof-input:focus, .kof-select:focus, .kof-textarea:focus {
      border-color: var(--orange);
      box-shadow: 0 0 0 3px rgba(242, 140, 56, 0.14);
    }

    .kof-textarea {
      min-height: 76px;
      resize: vertical;
    }

    .btn-navy {
      background: var(--navy) !important;
      border: 1px solid var(--navy) !important;
      color: #ffffff !important;
      border-radius: 8px !important;
      padding: 9px 16px !important;
      font-size: 13px !important;
      font-weight: 600 !important;
      cursor: pointer;
      transition: background 0.15s ease;
    }

    .btn-navy:hover {
      background: var(--navy-hover) !important;
    }

    .btn-navy.full-width {
      width: 100%;
      justify-content: center;
      margin-top: 6px;
    }

    .btn-outline {
      background: var(--bg-card) !important;
      border: 1px solid var(--border-strong) !important;
      color: var(--fg-secondary) !important;
      border-radius: 8px !important;
      padding: 9px 14px !important;
      font-size: 13px !important;
      font-weight: 500 !important;
      cursor: pointer;
    }

    .btn-outline:hover {
      background: var(--bg-muted) !important;
    }

    .btn-danger-soft {
      background: #fee2e2 !important;
      border: 1px solid #fecaca !important;
      color: #dc2626 !important;
      border-radius: 8px !important;
      padding: 9px 14px !important;
      font-size: 13px !important;
      font-weight: 600 !important;
      cursor: pointer;
    }

    /* ======================================================================
       MOVIMENTACOES & TRATAMENTOS (TELA 5 - IMAGEM 4)
       ====================================================================== */
    .mov-form-grid {
      display: grid !important;
      grid-template-columns: 1fr 1fr;
      gap: 24px !important;
      align-items: start !important;
      width: 100%;
    }

    .mov-form-col {
      display: flex !important;
      flex-direction: column !important;
      gap: 14px !important;
    }

    .mov-type-row {
      display: grid !important;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px !important;
      width: 100%;
    }

    .mov-type-btn {
      background: var(--orange-soft) !important;
      border: 1px solid transparent !important;
      color: var(--orange) !important;
      border-radius: 8px !important;
      padding: 12px 14px !important;
      font-size: 13px !important;
      font-weight: 600 !important;
      cursor: pointer;
      text-align: center;
    }

    .mov-type-btn.active {
      background: var(--orange) !important;
      color: #ffffff !important;
      box-shadow: 0 3px 10px rgba(242, 140, 56, 0.28);
    }

    .mov-footer-actions {
      display: flex !important;
      flex-direction: row !important;
      justify-content: flex-end !important;
      gap: 10px !important;
      width: 100%;
    }

    /* ======================================================================
       CONFIGURACOES & PERFIL DO USUARIO (TELA 6 - IMAGEM 3)
       ====================================================================== */
    .settings-two-col-grid {
      display: grid !important;
      grid-template-columns: 1.55fr 1fr;
      gap: 22px !important;
      align-items: start !important;
      width: 100%;
    }

    .settings-col-left, .settings-col-right {
      display: flex !important;
      flex-direction: column !important;
      gap: 20px !important;
    }

    .switch-row {
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      justify-content: space-between !important;
      padding: 6px 0;
      width: 100%;
    }

    .switch-text-col {
      display: flex !important;
      flex-direction: column !important;
      gap: 2px !important;
    }

    .switch-title {
      font-size: 13px !important;
      font-weight: 600 !important;
      color: var(--fg) !important;
    }

    .switch-sub {
      font-size: 11.5px !important;
      color: var(--fg-muted) !important;
    }

    .estocae-switch {
      width: 44px !important;
      height: 24px !important;
      min-width: 44px !important;
      border-radius: 999px !important;
      border: none !important;
      padding: 2px !important;
      position: relative;
      cursor: pointer;
      transition: background 0.2s ease;
    }

    .estocae-switch.on {
      background: var(--orange) !important;
    }

    .estocae-switch.off {
      background: #cbd5e1 !important;
    }

    .estocae-switch::after {
      content: "";
      position: absolute;
      top: 3px;
      width: 18px;
      height: 18px;
      border-radius: 50%;
      background: #ffffff;
      transition: left 0.2s ease;
      box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
    }

    .estocae-switch.on::after { left: 23px; }
    .estocae-switch.off::after { left: 3px; }

    .email-add-row {
      display: flex !important;
      flex-direction: row !important;
      gap: 8px !important;
      width: 100%;
    }

    .btn-orange-square {
      background: var(--orange) !important;
      border: none !important;
      color: #ffffff !important;
      width: 38px !important;
      height: 38px !important;
      border-radius: 8px !important;
      font-size: 18px !important;
      font-weight: 700 !important;
      cursor: pointer;
      flex-shrink: 0;
    }

    .email-chip-row {
      background: #f1f5f9;
      border-radius: 8px;
      padding: 8px 12px;
      display: flex !important;
      flex-direction: row !important;
      justify-content: space-between !important;
      align-items: center !important;
      font-size: 12.5px;
      color: var(--fg-secondary);
    }

    .profile-header-center {
      display: flex !important;
      flex-direction: column !important;
      align-items: center !important;
      gap: 4px !important;
      padding: 10px 0 6px;
    }

    .profile-avatar-large {
      width: 78px;
      height: 78px;
      border-radius: 50%;
      background: linear-gradient(135deg, #f28c38, #e11d48);
      color: #ffffff !important;
      font-size: 26px !important;
      font-weight: 800 !important;
      display: inline-flex !important;
      align-items: center;
      justify-content: center;
      position: relative;
      box-shadow: 0 4px 12px rgba(242, 140, 56, 0.3);
      margin-bottom: 6px;
    }

    .profile-display-name {
      font-size: 15px !important;
      font-weight: 700 !important;
      color: var(--fg) !important;
    }

    .profile-display-email {
      font-size: 12px !important;
      color: var(--fg-muted) !important;
    }

    .sys-info-box {
      background: #e5e7eb;
      color: var(--fg-secondary) !important;
      padding: 9px 12px;
      border-radius: 7px;
      font-size: 12.5px !important;
      font-weight: 500 !important;
      width: 100%;
    }

    .sys-info-box.status-ok {
      background: #dcfce7;
      color: #15803d !important;
      font-weight: 600 !important;
    }

    /* ======================================================================
       TABLES, BADGES, PROGRESS BARS & PAGINATION
       ====================================================================== */
    .kof-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }

    .kof-table thead th {
      color: var(--fg-muted);
      font-weight: 600;
      text-transform: uppercase;
      font-size: 11px;
      letter-spacing: 0.04em;
      padding: 12px 14px;
      text-align: left;
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
    }

    .kof-table tbody td {
      padding: 14px;
      border-bottom: 1px solid var(--border);
      color: var(--fg-secondary);
      vertical-align: middle;
    }

    .kof-table tbody tr:hover td {
      background: rgba(241, 245, 249, 0.6);
    }

    .prod-cell {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .prod-cube {
      width: 36px;
      height: 36px;
      border-radius: 8px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 15px;
      flex-shrink: 0;
    }

    .prod-cube.solid-orange {
      background: var(--orange);
      color: #ffffff;
    }

    .prod-cube.pastel-blue { background: #e0edff; color: #1e293b; }
    .prod-cube.pastel-purple { background: #f3e8ff; color: #1e293b; }
    .prod-cube.pastel-amber { background: #fef3c7; color: #1e293b; }
    .prod-cube.pastel-green { background: #dcfce7; color: #1e293b; }

    .prod-meta {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .prod-name {
      font-weight: 600;
      color: var(--fg);
      font-size: 13px;
    }

    .prod-sku {
      font-size: 11px;
      color: var(--fg-muted);
    }

    .stock-progress-cell {
      display: flex;
      flex-direction: column;
      gap: 5px;
      min-width: 140px;
    }

    .stock-qty-lbl {
      font-size: 12px;
      color: var(--fg-secondary);
    }

    .stock-bar-track {
      width: 100%;
      height: 6px;
      background: #e2e8f0;
      border-radius: 999px;
      overflow: hidden;
    }

    .stock-bar-fill {
      height: 100%;
      border-radius: 999px;
    }

    .stock-bar-fill.bar-green { background: #16a34a; }
    .stock-bar-fill.bar-red { background: #dc2626; }
    .stock-bar-fill.bar-amber { background: #f59e0b; }

    .estocae-badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 82px;
      padding: 5px 14px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 600;
    }

    .badge-green { background: #dcfce7; color: #16a34a; }
    .badge-red { background: #fee2e2; color: #ef4444; }
    .badge-amber { background: #fef3c7; color: #d97706; }
    .badge-blue { background: #dbeafe; color: #2563eb; }

    .qty-plus { color: #16a34a; font-weight: 700; }
    .qty-minus { color: #ef4444; font-weight: 700; }
    .qty-neutral { color: #2563eb; font-weight: 700; }

    .table-action-icons {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      color: var(--fg-muted);
      font-size: 15px;
      cursor: pointer;
    }

    .act-ico:hover { color: var(--fg); }
    .act-ico.danger:hover { color: var(--red); }

    .pagination-bar {
      display: flex !important;
      flex-direction: row !important;
      justify-content: center !important;
      align-items: center !important;
      gap: 6px !important;
      padding-top: 8px;
    }

    .page-btn {
      background: transparent !important;
      border: none !important;
      width: 28px !important;
      height: 28px !important;
      border-radius: 50% !important;
      font-size: 12px !important;
      font-weight: 600 !important;
      color: var(--fg-muted) !important;
      cursor: pointer;
      padding: 0 !important;
    }

    .page-btn.active {
      background: #e0edff !important;
      color: #2563eb !important;
    }

    .kof-hr {
      width: 100%;
      border: none;
      border-top: 1px solid var(--border);
      margin: 4px 0;
    }

    @media (max-width: 1180px) {
      .kpi-grid { grid-template-columns: repeat(2, 1fr); }
      .dash-charts-grid, .dash-bottom-grid, .settings-two-col-grid, .mov-form-grid {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <div id="kof-root"></div>
  <script type="module" src="/ui/Default.mjs"></script>
  <script type="module">
    const applyTabFromUrl = () => {
      const params = new URLSearchParams(window.location.search);
      const tab = params.get("tab");
      if (tab) {
        const btnTab = document.getElementById("tab-" + tab);
        if (btnTab) btnTab.click();
      }
    };
    applyTabFromUrl();
    window.addEventListener("load", () => {
      applyTabFromUrl();
      setTimeout(() => {
        const btnSync = document.getElementById("btn-sync");
        const btnDemo = document.getElementById("btn-seed-demo");
        const kpiPastos = document.getElementById("kpi-pastos-val");
        if (btnSync) {
          btnSync.click();
          if (kpiPastos && kpiPastos.textContent.trim() === "0" && btnDemo) {
            btnDemo.click();
          }
        }
        applyTabFromUrl();
      }, 60);
    });
  </script>
</body>
</html>
EOF

echo "Bundle Web KOF (Padrao Estocae) atualizado com sucesso em ${PUBLIC_DIR}/"
