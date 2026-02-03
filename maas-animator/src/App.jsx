import { useEffect, useMemo, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import "./App.css";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const clamp01 = (x) => Math.max(0, Math.min(1, x));

const CLIENTS = [
  {
    id: "VA",
    name: "Client: Virginia (East Coast)",
    dot: { x: 140, y: 160 },
    siteAffinity: { NMSU: 0.35, NMT: 0.45, NTU: 0.75 },
    note: "Remote enterprise order via Internet/WAN",
  },
  {
    id: "CA",
    name: "Client: California (West Coast)",
    dot: { x: 90, y: 210 },
    siteAffinity: { NMSU: 0.20, NMT: 0.25, NTU: 0.65 },
    note: "Lower WAN penalty to Southwest sites",
  },
  {
    id: "IT",
    name: "Client: Italy (EU)",
    dot: { x: 220, y: 145 },
    siteAffinity: { NMSU: 0.70, NMT: 0.75, NTU: 0.55 },
    note: "Cross-Atlantic + inter-domain routing",
  },
  {
    id: "ET",
    name: "Client: Ethiopia (Africa)",
    dot: { x: 240, y: 205 },
    siteAffinity: { NMSU: 0.78, NMT: 0.82, NTU: 0.58 },
    note: "Higher WAN RTT; SDN chooses best reachable site",
  },
  {
    id: "TW",
    name: "Client: Taiwan (Asia)",
    dot: { x: 315, y: 160 },
    siteAffinity: { NMSU: 0.75, NMT: 0.78, NTU: 0.40 },
    note: "Prefer Asia-side site (NTU) if healthy",
  },
];

function scorePrinter(p, client) {
  const health = clamp01(p.health);
  const latencyScore = 1 - clamp01(p.latencyMs / 280);
  const queueScore = 1 - clamp01(p.queue / 10);
  const wanPenalty = clamp01(client.siteAffinity[p.site] ?? 0.2);
  const wanScore = 1 - wanPenalty;

  return 0.45 * health + 0.20 * latencyScore + 0.15 * queueScore + 0.20 * wanScore;
}

function pickBest(printers, mode, preferredSite, client) {
  const pool = mode === "SITE" ? printers.filter((p) => p.site === preferredSite) : printers;
  return [...pool].map((p) => ({ ...p, score: scorePrinter(p, client) })).sort((a, b) => b.score - a.score)[0];
}

function Badge({ label, value }) {
  return (
    <div className="badge">
      <div className="badgeLabel">{label}</div>
      <div className="badgeValue">{value}</div>
    </div>
  );
}

export default function App() {
  const [mode, setMode] = useState("AUTO"); // AUTO | SITE
  const [site, setSite] = useState("NMSU");
  const [clientId, setClientId] = useState("ET");

  const [stage, setStage] = useState("idle");
  const [busy, setBusy] = useState(false);
  const [jobId, setJobId] = useState(400);
  const [selectedPrinterId, setSelectedPrinterId] = useState(null);
  const [inspectedId, setInspectedId] = useState(null);

  // NEW: for MasterNode interactivity
  const [k8sFocus, setK8sFocus] = useState("apiserver"); // apiserver|etcd|scheduler|controller|cloudccm

  const client = useMemo(() => CLIENTS.find((c) => c.id === clientId) ?? CLIENTS[0], [clientId]);

  const [printers, setPrinters] = useState(() => [
    { id: "NMSU-P1", site: "NMSU", model: "Prusa MK4", health: 0.88, latencyMs: 55, queue: 2 },
    { id: "NMSU-P2", site: "NMSU", model: "Ultimaker S5", health: 0.76, latencyMs: 62, queue: 4 },
    { id: "NMSU-P3", site: "NMSU", model: "Bambu X1C", health: 0.91, latencyMs: 48, queue: 5 },

    { id: "NMT-P1", site: "NMT", model: "Prusa MK3S+", health: 0.83, latencyMs: 95, queue: 1 },
    { id: "NMT-P2", site: "NMT", model: "Raise3D Pro3", health: 0.69, latencyMs: 110, queue: 3 },
    { id: "NMT-P3", site: "NMT", model: "Ender-5 S1", health: 0.72, latencyMs: 120, queue: 6 },

    { id: "NTU-P1", site: "NTU", model: "Formlabs Fuse", health: 0.86, latencyMs: 190, queue: 2 },
    { id: "NTU-P2", site: "NTU", model: "Ultimaker S7", health: 0.79, latencyMs: 205, queue: 4 },
    { id: "NTU-P3", site: "NTU", model: "Prusa XL", health: 0.93, latencyMs: 175, queue: 7 },
  ]);

  useEffect(() => {
    const t = setInterval(() => {
      setPrinters((prev) =>
        prev.map((p) => {
          const health = clamp01(p.health + (Math.random() - 0.5) * 0.02);
          const latencyMs = Math.max(25, Math.round(p.latencyMs + (Math.random() - 0.5) * 14));
          const qDelta = Math.random() < 0.35 ? (Math.random() < 0.5 ? -1 : 1) : 0;
          const queue = Math.max(0, Math.min(10, p.queue + qDelta));
          return { ...p, health, latencyMs, queue };
        })
      );
    }, 1500);
    return () => clearInterval(t);
  }, []);

  const best = useMemo(() => pickBest(printers, mode, site, client), [printers, mode, site, client]);

  useEffect(() => {
    if (!best) return;
    setSelectedPrinterId((prev) => {
      if (!prev) return prev;
      if (mode === "SITE") {
        const p = printers.find((x) => x.id === prev);
        if (p && p.site !== site) return null;
      }
      return prev;
    });
  }, [best, mode, site, printers]);

  const selectedPrinter = useMemo(() => {
    const id = selectedPrinterId ?? best?.id;
    return printers.find((p) => p.id === id);
  }, [printers, selectedPrinterId, best]);

  const inspected = useMemo(() => {
    const id = inspectedId ?? selectedPrinter?.id;
    return id ? printers.find((p) => p.id === id) : null;
  }, [printers, inspectedId, selectedPrinter]);

  const kpis = useMemo(() => {
    const chosen = selectedPrinter ?? best;
    if (!chosen) return null;
    const s = scorePrinter(chosen, client);
    return {
      chosen: chosen.id,
      site: chosen.site,
      score: s,
      health: chosen.health,
      queue: chosen.queue,
      rtt: chosen.latencyMs,
      wanPenalty: clamp01(client.siteAffinity[chosen.site] ?? 0.5),
    };
  }, [selectedPrinter, best, client]);

  async function runOrder() {
    if (busy) return;
    setBusy(true);

    const nextJob = jobId + 1;
    setJobId(nextJob);

    setSelectedPrinterId(null);
    setStage("order_submitted");
    await sleep(900);

    setStage("app_plane");
    await sleep(1200);

    setStage("sdn_request");
    await sleep(1200);

    const chosen = pickBest(printers, mode, site, client);
    setSelectedPrinterId(chosen.id);
    setStage("sdn_install");
    await sleep(1200);

    setStage("dispatch");
    await sleep(1400);

    setPrinters((prev) => prev.map((p) => (p.id === chosen.id ? { ...p, queue: Math.min(10, p.queue + 1) } : p)));

    setStage("telemetry");
    await sleep(1500);

    setStage("completed");
    await sleep(900);

    setStage("idle");
    setBusy(false);
  }

  function onPreferredSiteChange(newSite) {
    setSite(newSite);
    setMode("SITE");
    setSelectedPrinterId(null);
  }

  const statusText = (() => {
    switch (stage) {
      case "idle":
        return "Idle: Choose client + routing policy. AUTO routes across sites; SITE constrains routing to your chosen campus.";
      case "order_submitted":
        return `Order submitted (Job #${jobId}) from ${client.name}.`;
      case "app_plane":
        return "Application Plane: Client → Web Order App (order intake). Marketplace + Job Manager handle fulfillment.";
      case "sdn_request":
        return "Control Plane: Job Manager → SDN Controller (REST) using Policy + SLA intent.";
      case "sdn_install":
        return `SDN decision: select ${selectedPrinterId} (policy: ${mode}${mode === "SITE" ? ` → ${site}` : ""}).`;
      case "dispatch":
        return "Data Plane: Steer order traffic to selected site and dispatch the print job.";
      case "telemetry":
        return "Telemetry Loop: Printer → OVS → Telemetry Agent → Cloud; Policy → Security Agent → OVS (rules).";
      case "completed":
        return "Job completed ✅ (Multi-site MaaS cycle demonstrated).";
      default:
        return "";
    }
  })();

  /**
   * LAYOUT
   */
  const W = 1850;
  const H = 520;

  const geo = { x: 40, y: 20, w: 370, h: 480 };
  const master = { x: 430, y: 20, w: 350, h: 480 };
  const cloud = { x: 810, y: 20, w: 460, h: 480 };
  const edge = { x: 1290, y: 20, w: 520, h: 480 };

  const cloudInner = { x: cloud.x + 12, y: cloud.y + 60, w: cloud.w - 24 };
  const cGapX = 12;
  const cGapY = 34;
  const cCardW = (cloudInner.w - cGapX) / 2;
  const cCardH = 86;

  const cPos = (row, col) => {
    const x = cloudInner.x + col * (cCardW + cGapX);
    const y = cloudInner.y + row * (cCardH + cGapY);
    return { x, y, w: cCardW, h: cCardH, cx: x + cCardW / 2, cy: y + cCardH / 2 };
  };

  const pts = {
    web: cPos(0, 0),
    policy: cPos(0, 1),
    market: cPos(1, 0),
    sla: cPos(1, 1),
    job: cPos(2, 0),
    sdn: cPos(2, 1),

    ovs: { x: edge.x + 20, y: edge.y + 360 },
    telemetry: { x: edge.x + 250, y: edge.y + 360 },
    security: { x: edge.x + 387, y: edge.y + 360 },
  };

  const sitePanels = [
    { name: "NMSU", x: edge.x + 20, y: edge.y + 70, w: 150, h: 260 },
    { name: "NMT", x: edge.x + 185, y: edge.y + 70, w: 150, h: 260 },
    { name: "NTU", x: edge.x + 350, y: edge.y + 70, w: 150, h: 260 },
  ];

  const bySite = useMemo(() => {
    const m = { NMSU: [], NMT: [], NTU: [] };
    for (const p of printers) m[p.site].push(p);
    return m;
  }, [printers]);

  const printerPositions = useMemo(() => {
    const pos = {};
    for (const sp of sitePanels) {
      const items = bySite[sp.name] ?? [];
      const startY = sp.y + 56;
      const cardH = 56;
      const gap = 16;
      items.forEach((p, i) => {
        const y = startY + i * (cardH + gap);
        pos[p.id] = {
          x: sp.x + 10,
          y,
          w: sp.w - 20,
          h: cardH,
          cx: sp.x + sp.w / 2,
          cy: y + cardH / 2,
        };
      });
    }
    return pos;
  }, [bySite, sitePanels]);

  const selectedPos = selectedPrinter ? printerPositions[selectedPrinter.id] : null;

  const mapOrigin = { x: geo.x + 16, y: geo.y + 100 };
  const clientAbs = {
    x: mapOrigin.x + (client.dot?.x ?? 140),
    y: mapOrigin.y + (client.dot?.y ?? 160),
  };

  // Paths (architectural spines)
  const pathClientToWeb = `M ${clientAbs.x} ${clientAbs.y} L ${pts.web.cx} ${pts.web.cy}`;

  // CloudNode: two vertical columns (clean architectural look)
  const pathCloudLeftSpine = `M ${pts.web.cx} ${pts.web.y + 8} L ${pts.web.cx} ${pts.job.y + pts.job.h - 8}`;
  const pathCloudRightSpine = `M ${pts.sdn.cx} ${cloud.y + 64} L ${pts.sdn.cx} ${pts.sdn.cy}`;

  // Minimal horizontal hop
  const pathJobToSDN = `M ${pts.job.x + pts.job.w} ${pts.job.cy} L ${pts.sdn.x} ${pts.sdn.cy}`;

  // Edge interaction (as in previous architecture)
  const pathSDNToEdge = `M ${pts.sdn.x + pts.sdn.w} ${pts.sdn.cy} L ${pts.ovs.x + 120} ${pts.ovs.y + 20}`;

  // Data plane: OVS → selected printer
  const pathEdgeToPrinter = selectedPos
    ? `M ${pts.ovs.x + 120} ${pts.ovs.y + 20} L ${selectedPos.cx} ${selectedPos.cy}`
    : `M ${pts.ovs.x + 120} ${pts.ovs.y + 20} L ${pts.ovs.x + 120} ${pts.ovs.y + 20}`;

  // Telemetry MUST traverse OVS before reaching Telemetry Agent
  const pathPrinterToOVS = selectedPos
    ? `M ${selectedPos.cx} ${selectedPos.cy} L ${pts.ovs.x + 120} ${pts.ovs.y + 20}`
    : `M ${pts.ovs.x + 120} ${pts.ovs.y + 20} L ${pts.ovs.x + 120} ${pts.ovs.y + 20}`;

  const pathOVSToTelemetryHop = `M ${pts.ovs.x + 200} ${pts.ovs.y + 36} L ${pts.telemetry.x} ${pts.telemetry.y + 36}`;

  // Telemetry feedback to Cloud (Telemetry Agent → SLA Intelligence)
  const pathAgentsToSLA = `M ${pts.telemetry.x + 121} ${pts.telemetry.y + 41} L ${pts.sla.cx} ${pts.sla.y + pts.sla.h}`;

  // Security instructions (Cloud policy → Security agent → OVS)
  const pathCloudToSecurity = `M ${pts.policy.x + pts.policy.w} ${pts.policy.cy} L ${pts.security.x + 10} ${pts.security.y + 41}`;
  const pathSecurityToOVS = `M ${pts.security.x + 10} ${pts.security.y + 56} L ${pts.ovs.x + 200} ${pts.ovs.y + 56}`;

  // Curved / sinusoidal-style animated flows (for long-distance feel)
  const flowClientToCloud = `M ${clientAbs.x} ${clientAbs.y}
    C ${clientAbs.x + 120} ${clientAbs.y - 80}, ${cloud.x - 180} ${pts.web.cy - 40}, ${pts.web.x + 18} ${pts.web.cy}
    S ${pts.web.cx} ${pts.web.cy + 70}, ${pts.web.cx} ${pts.web.cy + 8}`;

  const flowCloudToSDN = `M ${pts.job.x + pts.job.w} ${pts.job.cy}
    C ${cloud.x + cloud.w - 90} ${pts.job.cy - 60}, ${cloud.x + cloud.w - 90} ${pts.sdn.cy + 60}, ${pts.sdn.x} ${pts.sdn.cy}`;

  const flowSDNToPrinter = selectedPos
    ? `M ${pts.sdn.x + pts.sdn.w} ${pts.sdn.cy}
        C ${edge.x - 80} ${pts.sdn.cy - 60}, ${edge.x - 40} ${pts.ovs.y - 10}, ${pts.ovs.x + 120} ${pts.ovs.y + 20}
        S ${selectedPos.cx - 80} ${selectedPos.cy + 70}, ${selectedPos.cx} ${selectedPos.cy}`
    : `M ${pts.sdn.x + pts.sdn.w} ${pts.sdn.cy}
        C ${edge.x - 80} ${pts.sdn.cy - 60}, ${edge.x - 40} ${pts.ovs.y - 10}, ${pts.ovs.x + 120} ${pts.ovs.y + 20}`;

  // Telemetry: Printer → OVS → Telemetry Agent → Cloud (SLA)
  const flowPrinterToOVS = selectedPos
    ? `M ${selectedPos.cx} ${selectedPos.cy}
        C ${selectedPos.cx + 120} ${selectedPos.cy + 80}, ${pts.ovs.x + 40} ${pts.ovs.y - 40}, ${pts.ovs.x + 120} ${pts.ovs.y + 20}`
    : `M ${pts.ovs.x + 120} ${pts.ovs.y + 20} L ${pts.ovs.x + 120} ${pts.ovs.y + 20}`;

  const flowOVSToTelemetry = `M ${pts.ovs.x + 200} ${pts.ovs.y + 36}
    C ${pts.ovs.x + 260} ${pts.ovs.y + 6}, ${pts.telemetry.x - 30} ${pts.telemetry.y + 8}, ${pts.telemetry.x} ${pts.telemetry.y + 36}`;

  const flowTelemetryToCloud = `M ${pts.telemetry.x + 121} ${pts.telemetry.y + 41}
    C ${edge.x + 520} ${edge.y + 520}, ${cloud.x + cloud.w + 60} ${cloud.y + 520}, ${pts.sla.cx} ${pts.sla.y + pts.sla.h}`;

  // Security: Policy intent → Security Agent → OVS (rules enforced at the bridge)
  const flowCloudToSecurity = `M ${pts.policy.x + pts.policy.w} ${pts.policy.cy}
    C ${cloud.x + cloud.w + 80} ${pts.policy.cy + 40}, ${edge.x + 470} ${pts.security.y - 40}, ${pts.security.x + 10} ${pts.security.y + 41}`;

  const flowSecurityToOVS = `M ${pts.security.x + 10} ${pts.security.y + 41}
    C ${edge.x + 520} ${pts.security.y + 120}, ${pts.ovs.x + 260} ${pts.ovs.y + 110}, ${pts.ovs.x + 200} ${pts.ovs.y + 56}`;

  function Dot({ d, show, label }) {
    return (
      <AnimatePresence>
        {show ? (
          <motion.g initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            <motion.circle
              r="7.5"
              fill="rgba(255,255,255,0.92)"
              stroke="rgba(73,214,255,0.95)"
              strokeWidth="3"
              filter="url(#glowCyan)"
              style={{ offsetPath: `path(\"${d}\")` }}
              initial={{ offsetDistance: "0%" }}
              animate={{ offsetDistance: "100%" }}
              transition={{ duration: 1.15, ease: "easeInOut" }}
            />
            {label ? (
              <motion.text x="18" y="20" fontSize="18" fontWeight="900" fill="rgba(255,255,255,0.90)" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                {label}
              </motion.text>
            ) : null}
          </motion.g>
        ) : null}
      </AnimatePresence>
    );
  }

  // SVG theme
  const panelFill = "rgba(255,255,255,0.035)";
  const panelStroke = "rgba(255,255,255,0.14)";
  const cardFill = "url(#cardGrad)";
  const cardStroke = "rgba(255,255,255,0.16)";
  const textMain = "rgba(255,255,255,0.92)";
  const textSub = "rgba(255,255,255,0.75)";
  const faintPath = "rgba(255,255,255,0.08)";

  const masterHot = stage === "app_plane" || stage === "sdn_request" || stage === "sdn_install";

  const K8S = [
    { key: "apiserver", label: "API Server", sub: "Cluster entrypoint" },
    { key: "etcd", label: "ETCD", sub: "State store" },
    { key: "scheduler", label: "Scheduler", sub: "Pod placement decisions" },
    { key: "controller", label: "Controller Manager", sub: "Reconcile desired state" },
    { key: "cloudccm", label: "Cloud Control Manager", sub: "Cloud LB/Routes/Nodes" },
  ];

  // Layout for 5 mini-cards inside MasterNode
  const masterInner = {
    x: master.x + 18,
    y: master.y + 90,
    w: master.w - 36,
    h: 320,
  };

  const kCardW = (masterInner.w - 24) / 2; // 2 columns
  const kCardH = 88;
  const kGapY = 32;
  const kGapX = 14;

  const kPos = (idx) => {
    // Arrange as:
    // row0: API, etcd
    // row1: Scheduler, Controller
    // row2: Cloud CCM (full width)
    if (idx === 4) {
      return {
        x: masterInner.x,
        y: masterInner.y + 2 * (kCardH + kGapY),
        w: masterInner.w,
        h: kCardH,
      };
    }
    const row = Math.floor(idx / 2);
    const col = idx % 2;
    return {
      x: masterInner.x + col * (kCardW + kGapX),
      y: masterInner.y + row * (kCardH + kGapY),
      w: kCardW,
      h: kCardH,
    };
  };

  const k8sDetail = useMemo(() => {
    const found = K8S.find((x) => x.key === k8sFocus) ?? K8S[0];
    return found;
  }, [k8sFocus]);

  return (
    <div className="page">
      <div className="topbar">
        <div>
          <div className="title">Manufacturing-as-a-Service (Multi-Site)</div>
          <div className="subtitle">Remote client → Web order microservice → SDN (REST) → site selection (NMSU/NMT/NTU) → distributed printers + telemetry feedback</div>
        </div>

        <div className="controls">
          <div className="ctrl">
            <div className="ctrlLabel">Client location</div>
            <select value={clientId} onChange={(e) => setClientId(e.target.value)}>
              {CLIENTS.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          <div className="ctrl">
            <div className="ctrlLabel">Routing</div>
            <select
              value={mode}
              onChange={(e) => {
                setMode(e.target.value);
                setSelectedPrinterId(null);
              }}
            >
              <option value="AUTO">AUTO (best across sites)</option>
              <option value="SITE">SITE (restrict to preferred site)</option>
            </select>
          </div>

          <div className="ctrl">
            <div className="ctrlLabel">Preferred site</div>
            <select value={site} onChange={(e) => onPreferredSiteChange(e.target.value)}>
              <option value="NMSU">NMSU</option>
              <option value="NMT">NMT</option>
              <option value="NTU">NTU</option>
            </select>
          </div>

          <button className="btn primary" onClick={runOrder} disabled={busy}>
            {busy ? "Running…" : "Submit Print Order"}
          </button>
        </div>
      </div>

      <div className="status">{statusText}</div>

      {kpis ? (
        <div className="kpis">
          <Badge label="Selected printer" value={kpis.chosen} />
          <Badge label="Selected site" value={kpis.site} />
          <Badge label="Score" value={kpis.score.toFixed(3)} />
          <Badge label="Health" value={kpis.health.toFixed(2)} />
          <Badge label="Queue" value={String(kpis.queue)} />
          <Badge label="RTT" value={`${kpis.rtt} ms`} />
        </div>
      ) : null}

      <div className="vizCard">
        <svg className="maasSvg" viewBox={`0 0 ${W} ${H}`}>
          <defs>
            <linearGradient id="cardGrad" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="rgba(255,255,255,0.11)" />
              <stop offset="100%" stopColor="rgba(255,255,255,0.04)" />
            </linearGradient>

            <filter id="glowCyan" x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation="3.2" result="blur" />
              <feColorMatrix
                in="blur"
                type="matrix"
                values="
                  0 0 0 0 0.29
                  0 0 0 0 0.84
                  0 0 0 0 1.00
                  0 0 0 0.75 0"
                result="cyan"
              />
              <feMerge>
                <feMergeNode in="cyan" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>

            <filter id="glowPink" x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation="3.2" result="blur" />
              <feColorMatrix
                in="blur"
                type="matrix"
                values="
                  0 0 0 0 1.00
                  0 0 0 0 0.31
                  0 0 0 0 0.85
                  0 0 0 0.75 0"
                result="pink"
              />
              <feMerge>
                <feMergeNode in="pink" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>

            <filter id="softShadow" x="-50%" y="-50%" width="200%" height="200%">
              <feDropShadow dx="0" dy="10" stdDeviation="10" floodColor="rgba(0,0,0,0.55)" />
            </filter>
          </defs>

          {/* Panels */}
          <rect x={geo.x} y={geo.y} width={geo.w} height={geo.h} rx="24" fill={panelFill} stroke={panelStroke} strokeWidth="2" />
          <text x={geo.x + 22} y={geo.y + 42} fontSize="26" fontWeight="900" fill={textMain}>
            Remote MaaS Client
          </text>

          <rect x={master.x} y={master.y} width={master.w} height={master.h} rx="24" fill={panelFill} stroke={panelStroke} strokeWidth="2" />
          <text x={master.x + 22} y={master.y + 42} fontSize="26" fontWeight="900" fill={textMain}>
            MasterNode (UNM)
          </text>

          <rect x={cloud.x} y={cloud.y} width={cloud.w} height={cloud.h} rx="24" fill={panelFill} stroke={panelStroke} strokeWidth="2" />
          <text x={cloud.x + 22} y={cloud.y + 42} fontSize="26" fontWeight="900" fill={textMain}>
            CloudNode (UNM)
          </text>

          <rect x={edge.x} y={edge.y} width={edge.w} height={edge.h} rx="24" fill={panelFill} stroke={panelStroke} strokeWidth="2" />
          <text x={edge.x + 22} y={edge.y + 42} fontSize="26" fontWeight="900" fill={textMain}>
            Distributed Edge Sites
          </text>

          {/* Master: 5 control-plane components (interactive) */}
          <motion.rect
            x={master.x + 10}
            y={master.y + 66}
            width={master.w - 26}
            height={382}
            rx="18"
            fill="rgba(255,255,255,0.02)"
            stroke="rgba(255,255,255,0.10)"
            strokeWidth="2"
            filter={masterHot ? "url(#glowCyan)" : undefined}
            animate={masterHot ? { opacity: [1, 0.92, 1] } : { opacity: 1 }}
            transition={{ duration: 1.8, repeat: masterHot ? Infinity : 0 }}
          />

          {K8S.map((k, idx) => {
            const r = kPos(idx);
            const active = k8sFocus === k.key;
            return (
              <g
                key={k.key}
                onMouseEnter={() => setK8sFocus(k.key)}
                onClick={() => setK8sFocus(k.key)}
                style={{ cursor: "pointer" }}
              >
                <motion.rect
                  x={r.x}
                  y={r.y}
                  width={r.w}
                  height={r.h}
                  rx="16"
                  fill="rgba(255,255,255,0.06)"
                  stroke={active ? "rgba(73,214,255,0.95)" : "rgba(255,255,255,0.16)"}
                  strokeWidth={active ? 2.8 : 2}
                  filter={active ? "url(#glowCyan)" : "url(#softShadow)"}
                  animate={active ? { scale: 1.02 } : { scale: 1 }}
                  transition={{ duration: 0.18 }}
                  style={{ transformOrigin: `${r.x + r.w / 2}px ${r.y + r.h / 2}px` }}
                />
                <text x={r.x + 14} y={r.y + 28} fontSize="14" fontWeight="900" fill={textMain}>
                  {k.label}
                </text>
                <text x={r.x + 14} y={r.y + 50} fontSize="12" fill={textSub}>
                  {k.sub}
                </text>
              </g>
            );
          })}

          {/* Geo map box */}
          <rect x={geo.x + 34} y={geo.y + 70} width={geo.w - 48} height={360} rx="18" fill={cardFill} stroke={cardStroke} strokeWidth="2" />
          <text x={geo.x + 44} y={geo.y + 120} fontSize="16" fill={textSub}>
            Client submits order over WAN / Internet
          </text>

          {/* World silhouettes */}
          <path
            d={`M ${mapOrigin.x + 30} ${mapOrigin.y + 120}
               C ${mapOrigin.x + 60} ${mapOrigin.y + 60}, ${mapOrigin.x + 140} ${mapOrigin.y + 60}, ${mapOrigin.x + 160} ${mapOrigin.y + 120}
               C ${mapOrigin.x + 180} ${mapOrigin.y + 180}, ${mapOrigin.x + 140} ${mapOrigin.y + 210}, ${mapOrigin.x + 90} ${mapOrigin.y + 210}
               C ${mapOrigin.x + 40} ${mapOrigin.y + 210}, ${mapOrigin.x + 10} ${mapOrigin.y + 170}, ${mapOrigin.x + 30} ${mapOrigin.y + 120} Z`}
            fill="rgba(255,255,255,0.05)"
            stroke="rgba(255,255,255,0.10)"
          />
          <path
            d={`M ${mapOrigin.x + 210} ${mapOrigin.y + 120}
               C ${mapOrigin.x + 240} ${mapOrigin.y + 80}, ${mapOrigin.x + 310} ${mapOrigin.y + 80}, ${mapOrigin.x + 330} ${mapOrigin.y + 130}
               C ${mapOrigin.x + 345} ${mapOrigin.y + 175}, ${mapOrigin.x + 315} ${mapOrigin.y + 210}, ${mapOrigin.x + 260} ${mapOrigin.y + 210}
               C ${mapOrigin.x + 225} ${mapOrigin.y + 210}, ${mapOrigin.x + 200} ${mapOrigin.y + 170}, ${mapOrigin.x + 210} ${mapOrigin.y + 120} Z`}
            fill="rgba(255,255,255,0.05)"
            stroke="rgba(255,255,255,0.10)"
          />

          {/* Client dot */}
          <motion.circle
            cx={clientAbs.x}
            cy={clientAbs.y}
            r="11"
            fill="rgba(255,255,255,0.92)"
            stroke="rgba(73,214,255,0.95)"
            strokeWidth="3"
            filter="url(#glowCyan)"
            animate={{ scale: [1, 1.14, 1] }}
            transition={{ duration: 1.8, repeat: Infinity }}
          />
          <text x={clientAbs.x + 16} y={clientAbs.y + 6} fontSize="16" fontWeight="900" fill={textMain}>
            Client
          </text>
          <text x={geo.x + 4} y={geo.y + 470} fontSize="16" fill={textSub}>
            {client.note}
          </text>

          {/* Cloud services (6 microservices) */}
          {/* Web Order App */}
          <rect x={pts.web.x} y={pts.web.y} width={pts.web.w} height={pts.web.h} rx="18" fill={cardFill} stroke={cardStroke} strokeWidth="2" filter="url(#softShadow)" />
          <text x={pts.web.x + 16} y={pts.web.y + 46} fontSize="18" fontWeight="950" fill={textMain}>
            Web Order App
          </text>
          <text x={pts.web.x + 16} y={pts.web.y + 70} fontSize="14" fill={textSub}>
            Order API • Auth • UI
          </text>

          {/* Policy Management System */}
          <rect x={pts.policy.x} y={pts.policy.y} width={pts.policy.w} height={pts.policy.h} rx="18" fill={cardFill} stroke={cardStroke} strokeWidth="2" filter="url(#softShadow)" />
          <text x={pts.policy.x + 16} y={pts.policy.y + 38} fontSize="17" fontWeight="950" fill={textMain}>
            Policy Management
          </text>
          <text x={pts.policy.x + 16} y={pts.policy.y + 60} fontSize="14" fill={textSub}>
            Constraints • Rules • Tags
          </text>
          <text x={pts.policy.x + 16} y={pts.policy.y + 78} fontSize="12" fill={textSub}>
            (system of record)
          </text>

          {/* Marketplace Microservice */}
          <rect x={pts.market.x} y={pts.market.y} width={pts.market.w} height={pts.market.h} rx="18" fill={cardFill} stroke={cardStroke} strokeWidth="2" filter="url(#softShadow)" />
          <text x={pts.market.x + 16} y={pts.market.y + 44} fontSize="18" fontWeight="950" fill={textMain}>
            Marketplace
          </text>
          <text x={pts.market.x + 16} y={pts.market.y + 70} fontSize="14" fill={textSub}>
            Listings • Price • Availability
          </text>

          {/* SLA Intelligence Microservice */}
          <rect x={pts.sla.x} y={pts.sla.y} width={pts.sla.w} height={pts.sla.h} rx="18" fill={cardFill} stroke={cardStroke} strokeWidth="2" filter="url(#softShadow)" />
          <text x={pts.sla.x + 16} y={pts.sla.y + 38} fontSize="17" fontWeight="950" fill={textMain}>
            SLA Intelligence
          </text>
          <text x={pts.sla.x + 16} y={pts.sla.y + 60} fontSize="14" fill={textSub}>
            Predict • Score • Alerts
          </text>
          <text x={pts.sla.x + 16} y={pts.sla.y + 78} fontSize="12" fill={textSub}>
            (QoS/SLA)
          </text>

          {/* Job Manager Microservice */}
          <rect x={pts.job.x} y={pts.job.y} width={pts.job.w} height={pts.job.h} rx="18" fill={cardFill} stroke={cardStroke} strokeWidth="2" filter="url(#softShadow)" />
          <text x={pts.job.x + 16} y={pts.job.y + 44} fontSize="18" fontWeight="950" fill={textMain}>
            Job Manager
          </text>
          <text x={pts.job.x + 16} y={pts.job.y + 70} fontSize="14" fill={textSub}>
            Orchestration • Scheduling
          </text>

          {/* SDN Controller */}
          <motion.rect
            x={pts.sdn.x}
            y={pts.sdn.y}
            width={pts.sdn.w}
            height={pts.sdn.h}
            rx="18"
            fill={cardFill}
            stroke={cardStroke}
            strokeWidth="2"
            filter={stage === "sdn_install" || stage === "sdn_request" ? "url(#glowCyan)" : "url(#softShadow)"}
            animate={stage === "sdn_install" || stage === "sdn_request" ? { scale: [1, 1.03, 1] } : { scale: 1 }}
            transition={{ duration: 1.2, repeat: stage === "sdn_install" || stage === "sdn_request" ? Infinity : 0 }}
            style={{ transformOrigin: `${pts.sdn.cx}px ${pts.sdn.cy}px` }}
          />
          <text x={pts.sdn.x + 16} y={pts.sdn.y + 42} fontSize="18" fontWeight="950" fill={textMain}>
            SDN Controller
          </text>
          <text x={pts.sdn.x + 16} y={pts.sdn.y + 66} fontSize="14" fill={textSub}>
            (ONOS)
          </text>

          {/* Edge: Site panels */}
          {sitePanels.map((sp) => {
            const isPreferred = mode === "SITE" && site === sp.name;
            return (
              <g key={sp.name}>
                <motion.rect
                  x={sp.x}
                  y={sp.y}
                  width={sp.w}
                  height={sp.h}
                  rx="18"
                  fill="rgba(255,255,255,0.05)"
                  stroke={isPreferred ? "rgba(255,79,216,0.95)" : "rgba(255,255,255,0.16)"}
                  strokeWidth={isPreferred ? 2.6 : 2}
                  filter={isPreferred ? "url(#glowPink)" : undefined}
                  animate={isPreferred ? { opacity: [1, 0.92, 1] } : { opacity: 1 }}
                  transition={{ duration: 1.6, repeat: isPreferred ? Infinity : 0 }}
                />
                <text x={sp.x + 12} y={sp.y + 30} fontSize="18" fontWeight="950" fill={textMain}>
                  {sp.name}
                </text>
                <text x={sp.x + 12} y={sp.y + 50} fontSize="12" fill={textSub}>
                  3D Printers
                </text>
              </g>
            );
          })}

          {/* Edge: OVS + Agents */}
          <rect x={pts.ovs.x} y={pts.ovs.y} width={200} height={82} rx="18" fill={cardFill} stroke={cardStroke} strokeWidth="2" filter="url(#softShadow)" />
          <text x={pts.ovs.x + 14} y={pts.ovs.y + 45} fontSize="19" fontWeight="950" fill={textMain}>
            Open vSwitch (OVS)
          </text>
          <text x={pts.ovs.x + 14} y={pts.ovs.y + 70} fontSize="14" fill={textSub}>
            Data Plane
          </text>

          {/* Telemetry Agent */}
          <rect x={pts.telemetry.x} y={pts.telemetry.y} width={121} height={82} rx="18" fill={cardFill} stroke={cardStroke} strokeWidth="2" filter="url(#softShadow)" />
          <text x={pts.telemetry.x + 10} y={pts.telemetry.y + 24} fontSize="15" fontWeight="950" fill={textMain}>
            Telemetry
          </text>
          <text x={pts.telemetry.x + 10} y={pts.telemetry.y + 38} fontSize="15" fontWeight="950" fill={textMain}>
            Agent
          </text>
          <text x={pts.telemetry.x + 12} y={pts.telemetry.y + 56} fontSize="12" fill={textSub}>
            Metrics • RTT
          </text>
          <text x={pts.telemetry.x + 12} y={pts.telemetry.y + 72} fontSize="12" fill={textSub}>
            Health • Queue
          </text>

          {/* Security Enforcement Agent */}
          <rect x={pts.security.x} y={pts.security.y} width={121} height={82} rx="18" fill={cardFill} stroke={cardStroke} strokeWidth="2" filter="url(#softShadow)" />
          <text x={pts.security.x + 10} y={pts.security.y + 24} fontSize="15" fontWeight="950" fill={textMain}>
            Security
          </text>
          <text x={pts.security.x + 10} y={pts.security.y + 38} fontSize="15" fontWeight="950" fill={textMain}>
            Enforcement
          </text>
          <text x={pts.security.x + 10} y={pts.security.y + 50} fontSize="15" fontWeight="950" fill={textMain}>
            Agent
          </text>
          <text x={pts.security.x + 12} y={pts.security.y + 72} fontSize="12" fill={textSub}>
            ACL • QoS Policies
          </text>

          {/* Base faint paths */}
          <path d={pathClientToWeb} fill="none" stroke={faintPath} strokeWidth="4" />
          <path d={pathCloudLeftSpine} fill="none" stroke={faintPath} strokeWidth="4" />
          <path d={pathCloudRightSpine} fill="none" stroke={faintPath} strokeWidth="4" />
          <path d={pathJobToSDN} fill="none" stroke={faintPath} strokeWidth="4" />
          <path d={pathSDNToEdge} fill="none" stroke={faintPath} strokeWidth="4" />
          <path d={pathEdgeToPrinter} fill="none" stroke={faintPath} strokeWidth="4" />

          {/* Telemetry traverses OVS then reaches Telemetry Agent */}
          <path d={pathPrinterToOVS} fill="none" stroke={faintPath} strokeWidth="4" />
          


          {/* Emphasized flowing dashed routing */}
          <AnimatePresence>
            {stage === "sdn_install" || stage === "dispatch" ? (
              <>
                <motion.path
                  d={flowCloudToSDN}
                  fill="none"
                  stroke="rgba(73,214,255,0.95)"
                  strokeWidth="7"
                  strokeLinecap="round"
                  strokeDasharray="14 10"
                  filter="url(#glowCyan)"
                  animate={{ strokeDashoffset: [0, -260] }}
                  transition={{ duration: 2.0, repeat: Infinity, ease: "linear" }}
                  opacity={0.95}
                />
                <motion.path
                  d={flowSDNToPrinter}
                  fill="none"
                  stroke="rgba(73,214,255,0.95)"
                  strokeWidth="8"
                  strokeLinecap="round"
                  strokeDasharray="14 10"
                  filter="url(#glowCyan)"
                  animate={{ strokeDashoffset: [0, -300] }}
                  transition={{ duration: 1.9, repeat: Infinity, ease: "linear" }}
                  opacity={0.98}
                />

                {/* Security intent: Cloud policy → Security Agent → OVS */}
                <motion.path
                  d={flowCloudToSecurity}
                  fill="none"
                  stroke="rgba(255,79,216,0.92)"
                  strokeWidth="6"
                  strokeLinecap="round"
                  strokeDasharray="12 10"
                  filter="url(#glowPink)"
                  animate={{ strokeDashoffset: [0, -260] }}
                  transition={{ duration: 2.2, repeat: Infinity, ease: "linear" }}
                  opacity={0.90}
                />
                <motion.path
                  d={flowSecurityToOVS}
                  fill="none"
                  stroke="rgba(255,79,216,0.92)"
                  strokeWidth="6"
                  strokeLinecap="round"
                  strokeDasharray="12 10"
                  filter="url(#glowPink)"
                  animate={{ strokeDashoffset: [0, -260] }}
                  transition={{ duration: 2.0, repeat: Infinity, ease: "linear" }}
                  opacity={0.90}
                />
              </>
            ) : null}
          </AnimatePresence>

          <AnimatePresence>
            {stage === "app_plane" ? (
              <motion.path
                d={flowClientToCloud}
                fill="none"
                stroke="rgba(73,214,255,0.92)"
                strokeWidth="7"
                strokeLinecap="round"
                strokeDasharray="12 10"
                filter="url(#glowCyan)"
                animate={{ strokeDashoffset: [0, -240] }}
                transition={{ duration: 2.2, repeat: Infinity, ease: "linear" }}
                opacity={0.95}
              />
            ) : null}
          </AnimatePresence>

          <AnimatePresence>
            {stage === "telemetry" ? (
              <>
                <motion.path
                  d={flowPrinterToOVS}
                  fill="none"
                  stroke="rgba(73,214,255,0.92)"
                  strokeWidth="7"
                  strokeLinecap="round"
                  strokeDasharray="10 10"
                  filter="url(#glowCyan)"
                  animate={{ strokeDashoffset: [0, -220] }}
                  transition={{ duration: 2.1, repeat: Infinity, ease: "linear" }}
                  opacity={0.95}
                />
                <motion.path
                  d={flowOVSToTelemetry}
                  fill="none"
                  stroke="rgba(73,214,255,0.92)"
                  strokeWidth="7"
                  strokeLinecap="round"
                  strokeDasharray="10 10"
                  filter="url(#glowCyan)"
                  animate={{ strokeDashoffset: [0, -220] }}
                  transition={{ duration: 2.1, repeat: Infinity, ease: "linear" }}
                  opacity={0.95}
                />
                <motion.path
                  d={flowTelemetryToCloud}
                  fill="none"
                  stroke="rgba(73,214,255,0.92)"
                  strokeWidth="7"
                  strokeLinecap="round"
                  strokeDasharray="10 10"
                  filter="url(#glowCyan)"
                  animate={{ strokeDashoffset: [0, -220] }}
                  transition={{ duration: 2.2, repeat: Infinity, ease: "linear" }}
                  opacity={0.92}
                />
              </>
            ) : null}
          </AnimatePresence>

          {/* Printer cards */}
          {printers.map((p) => {
            const r = printerPositions[p.id];
            if (!r) return null;

            const isSelected = selectedPrinterId === p.id && stage !== "idle";
            const isInspected = inspected?.id === p.id;

            return (
              <g key={p.id} onClick={() => setInspectedId(p.id)} style={{ cursor: "pointer" }}>
                <motion.rect
                  x={r.x}
                  y={r.y}
                  width={r.w}
                  height={r.h}
                  rx="14"
                  fill="rgba(255,255,255,0.06)"
                  stroke="rgba(255,255,255,0.16)"
                  strokeWidth="2"
                  animate={isSelected ? { scale: 1.03 } : { scale: 1 }}
                  transition={{ duration: 0.18 }}
                  style={{ transformOrigin: `${r.x + r.w / 2}px ${r.y + r.h / 2}px` }}
                />
                <text x={r.x + 10} y={r.y + 24} fontSize="13" fontWeight="950" fill={textMain}>
                  {p.id}
                </text>
                <text x={r.x + 10} y={r.y + 45} fontSize="12" fill={textSub}>
                  h:{p.health.toFixed(2)} q:{p.queue} rtt:{p.latencyMs}ms
                </text>

                {isSelected ? (
                  <motion.rect
                    x={r.x - 4}
                    y={r.y - 4}
                    width={r.w + 8}
                    height={r.h + 8}
                    rx="16"
                    fill="none"
                    stroke="rgba(73,214,255,0.95)"
                    strokeWidth="3"
                    filter="url(#glowCyan)"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                  />
                ) : null}

                {isInspected ? (
                  <motion.circle
                    cx={r.x + r.w - 12}
                    cy={r.y + 12}
                    r="6"
                    fill="rgba(255,255,255,0.92)"
                    stroke="rgba(167,139,250,0.90)"
                    strokeWidth="2"
                    filter="url(#glowPink)"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                  />
                ) : null}
              </g>
            );
          })}

          {/* Moving dots */}
          <Dot d={pathClientToWeb} show={stage === "order_submitted"} label={`Job #${jobId}`} />
          <Dot d={flowClientToCloud} show={stage === "app_plane"} />
          <Dot d={pathJobToSDN} show={stage === "sdn_request"} />
          <Dot d={pathEdgeToPrinter} show={stage === "dispatch"} label="Dispatch" />

          {/* Telemetry: Printer → OVS → Telemetry Agent → Cloud */}
          <Dot d={flowPrinterToOVS} show={stage === "telemetry"} label="Telemetry" />
          <Dot d={flowOVSToTelemetry} show={stage === "telemetry"} />
          <Dot d={pathAgentsToSLA} show={stage === "telemetry"} />
        </svg>
      </div>

      <div className="bottomPanel">
        <div className="panelTitle">Inspector</div>
        {inspected ? (
          <div className="inspectorGrid">
            <div className="inspectorCard">
              <div className="inspectorHead">{inspected.id}</div>
              <div className="row">
                <span>Site</span>
                <span>{inspected.site}</span>
              </div>
              <div className="row">
                <span>Model</span>
                <span>{inspected.model}</span>
              </div>
              <div className="row">
                <span>Health</span>
                <span>{inspected.health.toFixed(2)}</span>
              </div>
              <div className="row">
                <span>Queue</span>
                <span>{inspected.queue}</span>
              </div>
              <div className="row">
                <span>RTT</span>
                <span>{inspected.latencyMs} ms</span>
              </div>
            </div>

            <div className="inspectorCard">
              <div className="inspectorHead">Selection logic</div>
              <div className="row">
                <span>Mode</span>
                <span>{mode}</span>
              </div>
              <div className="row">
                <span>Preferred site</span>
                <span>{site}</span>
              </div>
              <div className="row">
                <span>Policy</span>
                <span>{mode === "SITE" ? "Restrict to preferred site" : "Best across sites"}</span>
              </div>
              <div className="row">
                <span>Score</span>
                <span>{scorePrinter(inspected, client).toFixed(3)}</span>
              </div>
              <div className="hint">
                Tip: hover/click the MasterNode components to highlight the Kubernetes control-plane role in orchestrating your MaaS pods.
              </div>
            </div>
          </div>
        ) : (
          <div className="hint">Click a printer to inspect it.</div>
        )}
      </div>

      <div className="footer">Tip: switch client geography + mode to demonstrate real multi-site MaaS with SDN policy steering.</div>
    </div>
  );
}