import React, { useState, useRef, useEffect } from "react";

// ─────────────────────────────────────────────────────────
// Adaptive Assessments — UI/UX Flow Diagram
// A presentation-ready wireflow showing how the existing
// questionnaire is translated into an adaptive front-end
// experience with conditional branching.
// ─────────────────────────────────────────────────────────

// ── Color Palette ──
const COLORS = {
  bg: "#F8F7F4",
  cardBg: "#FFFFFF",
  border: "#E2E0DB",
  borderLight: "#EEECE8",
  text: "#2C2A26",
  textMuted: "#8A8680",
  textLight: "#B0ACA6",

  // Stage colors
  welcome: "#3B7D6E",
  welcomeLight: "#EBF5F2",
  foundation: "#5B6AAF",
  foundationLight: "#ECEEF7",
  monthly: "#C27D3A",
  monthlyLight: "#FDF3E8",
  branch: "#9B5BA5",
  branchLight: "#F5ECF7",
  completion: "#3B7D6E",
  completionLight: "#EBF5F2",

  // Branch-specific
  mental: "#D4645C",
  mentalLight: "#FCEEED",
  physical: "#4A9B7F",
  physicalLight: "#E9F6F1",
  alcohol: "#C28B3A",
  alcoholLight: "#FDF5E8",
  womens: "#A872B0",
  womensLight: "#F5EDF7",
  dietary: "#6B8EBF",
  dietaryLight: "#EDF2F9",

  // Annotations
  annotationBg: "#FFFDE8",
  annotationBorder: "#E8E2B0",
  annotationText: "#7A7340",

  // Arrows
  arrow: "#C0BBB3",
  arrowYes: "#4A9B7F",
  arrowNo: "#D4645C",
};

// ── Fonts ──
const FONT = {
  display: "'Instrument Serif', Georgia, serif",
  body: "'DM Sans', 'Helvetica Neue', sans-serif",
  mono: "'JetBrains Mono', monospace",
};

// ── Shape Components ──

/**
 * Rounded rectangle representing a UI screen/state.
 */
function ScreenNode({ title, items, color, colorLight, icon, width = 280, annotation }) {
  return (
    <div
      style={{
        width,
        background: COLORS.cardBg,
        borderRadius: 14,
        border: `1.5px solid ${color}22`,
        boxShadow: `0 2px 12px ${color}10`,
        overflow: "hidden",
        position: "relative",
      }}
    >
      {/* Header bar */}
      <div
        style={{
          background: colorLight,
          padding: "10px 16px",
          display: "flex",
          alignItems: "center",
          gap: 8,
          borderBottom: `1px solid ${color}18`,
        }}
      >
        <span style={{ fontSize: 16 }}>{icon}</span>
        <span
          style={{
            fontFamily: FONT.body,
            fontWeight: 600,
            fontSize: 13,
            color: color,
            letterSpacing: "0.02em",
          }}
        >
          {title}
        </span>
      </div>

      {/* Content items */}
      {items && items.length > 0 && (
        <div style={{ padding: "10px 16px 14px" }}>
          {items.map((item, i) => (
            <div
              key={i}
              style={{
                fontFamily: FONT.body,
                fontSize: 12,
                color: COLORS.text,
                padding: "4px 0",
                lineHeight: 1.45,
                display: "flex",
                alignItems: "flex-start",
                gap: 6,
              }}
            >
              <span style={{ color: COLORS.textLight, fontSize: 10, marginTop: 2 }}>●</span>
              <span>{item}</span>
            </div>
          ))}
        </div>
      )}

      {/* Annotation badge */}
      {annotation && <AnnotationBadge text={annotation} />}
    </div>
  );
}

/**
 * Diamond shape representing a decision/condition point.
 */
function DecisionDiamond({ text, color, subtext }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
      <div
        style={{
          width: 140,
          height: 72,
          position: "relative",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        {/* Diamond shape via rotated square */}
        <div
          style={{
            position: "absolute",
            width: 58,
            height: 58,
            transform: "rotate(45deg)",
            background: `${color}12`,
            border: `1.5px solid ${color}40`,
            borderRadius: 6,
          }}
        />
        <span
          style={{
            position: "relative",
            zIndex: 1,
            fontFamily: FONT.body,
            fontSize: 10.5,
            fontWeight: 600,
            color: color,
            textAlign: "center",
            lineHeight: 1.3,
            maxWidth: 100,
          }}
        >
          {text}
        </span>
      </div>
      {subtext && (
        <span
          style={{
            fontFamily: FONT.mono,
            fontSize: 9,
            color: COLORS.textMuted,
            textAlign: "center",
          }}
        >
          {subtext}
        </span>
      )}
    </div>
  );
}

/**
 * Small annotation badge showing UX design pattern labels.
 */
function AnnotationBadge({ text }) {
  return (
    <div
      style={{
        position: "absolute",
        top: -8,
        right: -6,
        background: COLORS.annotationBg,
        border: `1px solid ${COLORS.annotationBorder}`,
        borderRadius: 20,
        padding: "2px 10px",
        fontFamily: FONT.mono,
        fontSize: 9,
        color: COLORS.annotationText,
        fontWeight: 500,
        whiteSpace: "nowrap",
        zIndex: 5,
      }}
    >
      {text}
    </div>
  );
}

/**
 * Vertical arrow connector between flow elements.
 */
function ArrowDown({ label, color = COLORS.arrow, height = 32 }) {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        height,
        position: "relative",
      }}
    >
      <div
        style={{
          width: 1.5,
          flex: 1,
          background: color,
        }}
      />
      <div
        style={{
          width: 0,
          height: 0,
          borderLeft: "5px solid transparent",
          borderRight: "5px solid transparent",
          borderTop: `6px solid ${color}`,
        }}
      />
      {label && (
        <span
          style={{
            position: "absolute",
            left: 12,
            top: "50%",
            transform: "translateY(-50%)",
            fontFamily: FONT.mono,
            fontSize: 9.5,
            fontWeight: 600,
            color: color,
            whiteSpace: "nowrap",
          }}
        >
          {label}
        </span>
      )}
    </div>
  );
}

/**
 * Section header for each major stage of the flow.
 */
function StageHeader({ number, title, color, colorLight }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 12,
        marginBottom: 16,
        marginTop: 8,
      }}
    >
      <div
        style={{
          width: 30,
          height: 30,
          borderRadius: "50%",
          background: color,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: FONT.body,
          fontSize: 14,
          fontWeight: 700,
          color: "#fff",
        }}
      >
        {number}
      </div>
      <span
        style={{
          fontFamily: FONT.display,
          fontSize: 20,
          color: COLORS.text,
          letterSpacing: "-0.01em",
        }}
      >
        {title}
      </span>
      <div
        style={{
          flex: 1,
          height: 1,
          background: `${color}25`,
          marginLeft: 8,
        }}
      />
    </div>
  );
}

/**
 * A single adaptive branch panel showing the trigger → decision → follow-up flow.
 */
function BranchPanel({ title, icon, color, colorLight, triggerQuestion, decision, yesPath, noPath, deeperPath, annotation }) {
  return (
    <div
      style={{
        background: COLORS.cardBg,
        border: `1.5px solid ${color}20`,
        borderRadius: 16,
        padding: 20,
        position: "relative",
        minWidth: 260,
        maxWidth: 300,
        boxShadow: `0 2px 16px ${color}08`,
      }}
    >
      {/* Branch header */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          marginBottom: 14,
          paddingBottom: 10,
          borderBottom: `1px solid ${COLORS.borderLight}`,
        }}
      >
        <span style={{ fontSize: 18 }}>{icon}</span>
        <span
          style={{
            fontFamily: FONT.body,
            fontSize: 14,
            fontWeight: 700,
            color: color,
          }}
        >
          {title}
        </span>
      </div>

      {/* Trigger question */}
      <div
        style={{
          background: colorLight,
          borderRadius: 10,
          padding: "10px 12px",
          marginBottom: 12,
          border: `1px solid ${color}15`,
        }}
      >
        <div
          style={{
            fontFamily: FONT.mono,
            fontSize: 9,
            color: COLORS.textMuted,
            marginBottom: 4,
            textTransform: "uppercase",
            letterSpacing: "0.08em",
          }}
        >
          Trigger Question
        </div>
        <div
          style={{
            fontFamily: FONT.body,
            fontSize: 11.5,
            color: COLORS.text,
            lineHeight: 1.45,
          }}
        >
          {triggerQuestion}
        </div>
      </div>

      {/* Decision diamond inline */}
      <div style={{ display: "flex", justifyContent: "center", margin: "8px 0" }}>
        <DecisionDiamond text={decision} color={color} />
      </div>

      {/* Yes/No paths */}
      <div style={{ display: "flex", gap: 10, marginTop: 8 }}>
        {/* Yes path */}
        <div style={{ flex: 1 }}>
          <div
            style={{
              fontFamily: FONT.mono,
              fontSize: 9,
              fontWeight: 700,
              color: COLORS.arrowYes,
              marginBottom: 6,
              textAlign: "center",
            }}
          >
            ✓ YES
          </div>
          <div
            style={{
              background: `${COLORS.arrowYes}08`,
              border: `1px solid ${COLORS.arrowYes}20`,
              borderRadius: 8,
              padding: "8px 10px",
            }}
          >
            {yesPath.map((item, i) => (
              <div
                key={i}
                style={{
                  fontFamily: FONT.body,
                  fontSize: 10.5,
                  color: COLORS.text,
                  padding: "2px 0",
                  lineHeight: 1.4,
                }}
              >
                → {item}
              </div>
            ))}
          </div>
        </div>

        {/* No path */}
        <div style={{ flex: 1 }}>
          <div
            style={{
              fontFamily: FONT.mono,
              fontSize: 9,
              fontWeight: 700,
              color: COLORS.arrowNo,
              marginBottom: 6,
              textAlign: "center",
            }}
          >
            ✗ NO
          </div>
          <div
            style={{
              background: `${COLORS.arrowNo}08`,
              border: `1px solid ${COLORS.arrowNo}20`,
              borderRadius: 8,
              padding: "8px 10px",
            }}
          >
            {noPath.map((item, i) => (
              <div
                key={i}
                style={{
                  fontFamily: FONT.body,
                  fontSize: 10.5,
                  color: COLORS.text,
                  padding: "2px 0",
                  lineHeight: 1.4,
                }}
              >
                → {item}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Deeper follow-up path (risk-based expansion) */}
      {deeperPath && (
        <div style={{ marginTop: 10 }}>
          <div
            style={{
              background: `${color}10`,
              border: `1px dashed ${color}35`,
              borderRadius: 8,
              padding: "8px 10px",
            }}
          >
            <div
              style={{
                fontFamily: FONT.mono,
                fontSize: 9,
                color: color,
                fontWeight: 600,
                marginBottom: 4,
                textTransform: "uppercase",
                letterSpacing: "0.06em",
              }}
            >
              ⚠ {deeperPath.label}
            </div>
            {deeperPath.items.map((item, i) => (
              <div
                key={i}
                style={{
                  fontFamily: FONT.body,
                  fontSize: 10.5,
                  color: COLORS.text,
                  padding: "2px 0",
                  lineHeight: 1.4,
                }}
              >
                → {item}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Annotation */}
      {annotation && (
        <div
          style={{
            position: "absolute",
            top: -10,
            right: 10,
            background: COLORS.annotationBg,
            border: `1px solid ${COLORS.annotationBorder}`,
            borderRadius: 20,
            padding: "3px 12px",
            fontFamily: FONT.mono,
            fontSize: 9,
            color: COLORS.annotationText,
            fontWeight: 500,
            whiteSpace: "nowrap",
          }}
        >
          {annotation}
        </div>
      )}
    </div>
  );
}

// ── Main Diagram Component ──

export default function AdaptiveFlowDiagram() {
  const [activeStage, setActiveStage] = useState(null);

  return (
    <div
      style={{
        minHeight: "100vh",
        background: COLORS.bg,
        fontFamily: FONT.body,
        color: COLORS.text,
      }}
    >
      {/* Google Fonts */}
      <link
        href="https://fonts.googleapis.com/css2?family=Instrument+Serif&family=DM+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600;700&display=swap"
        rel="stylesheet"
      />

      {/* Header */}
      <div
        style={{
          background: "#FFFFFF",
          borderBottom: `1px solid ${COLORS.border}`,
          padding: "28px 40px 24px",
        }}
      >
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div
            style={{
              fontFamily: FONT.mono,
              fontSize: 10,
              color: COLORS.textMuted,
              textTransform: "uppercase",
              letterSpacing: "0.12em",
              marginBottom: 6,
            }}
          >
            FIT4702 · Adaptive Assessments
          </div>
          <h1
            style={{
              fontFamily: FONT.display,
              fontSize: 32,
              fontWeight: 400,
              color: COLORS.text,
              margin: 0,
              letterSpacing: "-0.02em",
            }}
          >
            Adaptive UI/UX Assessment Flow
          </h1>
          <p
            style={{
              fontFamily: FONT.body,
              fontSize: 14,
              color: COLORS.textMuted,
              marginTop: 8,
              maxWidth: 700,
              lineHeight: 1.55,
            }}
          >
            How the existing Questionnaire v4 is translated into an adaptive front-end experience.
            The UI dynamically adjusts which questions are shown based on user responses, eligibility,
            and risk levels — reducing irrelevant questions and improving engagement.
          </p>

          {/* Legend */}
          <div
            style={{
              display: "flex",
              gap: 20,
              marginTop: 16,
              flexWrap: "wrap",
            }}
          >
            {[
              { label: "UI Screen / State", shape: "rect", color: COLORS.textMuted },
              { label: "Decision Point", shape: "diamond", color: COLORS.textMuted },
              { label: "Yes Path", shape: "line", color: COLORS.arrowYes },
              { label: "No / Skip Path", shape: "line", color: COLORS.arrowNo },
              { label: "UX Pattern", shape: "badge", color: COLORS.annotationText },
            ].map((item, i) => (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 6 }}>
                {item.shape === "rect" && (
                  <div
                    style={{
                      width: 16,
                      height: 12,
                      borderRadius: 3,
                      border: `1.5px solid ${item.color}`,
                      background: "#fff",
                    }}
                  />
                )}
                {item.shape === "diamond" && (
                  <div
                    style={{
                      width: 10,
                      height: 10,
                      transform: "rotate(45deg)",
                      border: `1.5px solid ${item.color}`,
                      background: "#fff",
                    }}
                  />
                )}
                {item.shape === "line" && (
                  <div style={{ width: 16, height: 2, background: item.color, borderRadius: 1 }} />
                )}
                {item.shape === "badge" && (
                  <div
                    style={{
                      width: 16,
                      height: 12,
                      borderRadius: 6,
                      background: COLORS.annotationBg,
                      border: `1px solid ${COLORS.annotationBorder}`,
                    }}
                  />
                )}
                <span style={{ fontFamily: FONT.body, fontSize: 11, color: COLORS.textMuted }}>
                  {item.label}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Main Flow Content */}
      <div style={{ maxWidth: 1100, margin: "0 auto", padding: "32px 40px 60px" }}>

        {/* ──────── STAGE 1: Welcome ──────── */}
        <StageHeader number="1" title="Welcome / Entry" color={COLORS.welcome} colorLight={COLORS.welcomeLight} />

        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", marginBottom: 32 }}>
          <ScreenNode
            title="Welcome Screen"
            icon="👋"
            color={COLORS.welcome}
            colorLight={COLORS.welcomeLight}
            items={[
              "Platform introduction & purpose",
              "Brief explanation of adaptive assessment",
              "Consent & privacy acknowledgment",
              '"Begin Assessment" button',
            ]}
            width={320}
          />
          <ArrowDown height={36} />
        </div>

        {/* ──────── STAGE 2: Foundational Assessment ──────── */}
        <StageHeader
          number="2"
          title="Foundational Assessment"
          color={COLORS.foundation}
          colorLight={COLORS.foundationLight}
        />

        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", marginBottom: 12 }}>
          <div style={{ position: "relative" }}>
            <AnnotationBadge text="static · one-time baseline" />
            <ScreenNode
              title="Onboarding & Demographics"
              icon="📋"
              color={COLORS.foundation}
              colorLight={COLORS.foundationLight}
              items={[
                "Age, gender, ethnicity (Q1)",
                "Height & weight (Q7)",
                "Known allergies (Q8)",
              ]}
              width={320}
            />
          </div>
          <ArrowDown height={28} />

          <ScreenNode
            title="Health Background"
            icon="🏥"
            color={COLORS.foundation}
            colorLight={COLORS.foundationLight}
            items={[
              "Stress/anxiety baseline (Q2) — sets mental health flag",
              "Alcohol baseline (Q3) — sets drinking flag",
              "Smoking/vaping status (Q4)",
              "Surgery / hospitalisation history (Q5)",
              "Family chronic disease history (Q6)",
              "Current ongoing symptoms (open text)",
            ]}
            width={380}
          />

          <div
            style={{
              marginTop: 12,
              background: COLORS.foundationLight,
              border: `1px solid ${COLORS.foundation}20`,
              borderRadius: 10,
              padding: "10px 16px",
              maxWidth: 380,
              textAlign: "center",
            }}
          >
            <span style={{ fontFamily: FONT.mono, fontSize: 10, color: COLORS.foundation }}>
              ★ Responses here determine eligibility flags used in adaptive branching below
            </span>
          </div>

          <ArrowDown height={36} />
        </div>

        {/* ──────── STAGE 3: Core Monthly Check-In ──────── */}
        <StageHeader
          number="3"
          title="Core Monthly Check-In"
          color={COLORS.monthly}
          colorLight={COLORS.monthlyLight}
        />

        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", marginBottom: 12 }}>
          <div style={{ position: "relative" }}>
            <AnnotationBadge text="recurring · monthly" />
            <ScreenNode
              title="Monthly Core Questions"
              icon="📅"
              color={COLORS.monthly}
              colorLight={COLORS.monthlyLight}
              items={[
                "Small set of core questions across domains",
                "Acts as trigger point for adaptive branches",
                "Not all domains shown each month (rotation)",
                "Users see only relevant follow-up paths",
              ]}
              width={360}
            />
          </div>

          <div
            style={{
              marginTop: 14,
              display: "flex",
              gap: 10,
              flexWrap: "wrap",
              justifyContent: "center",
            }}
          >
            {[
              { label: "Mental Health", color: COLORS.mental, icon: "🧠" },
              { label: "Dietary", color: COLORS.dietary, icon: "🥗" },
              { label: "Physical Activity", color: COLORS.physical, icon: "🏃" },
              { label: "Alcohol", color: COLORS.alcohol, icon: "🍷" },
              { label: "Women's Health", color: COLORS.womens, icon: "♀" },
            ].map((d, i) => (
              <div
                key={i}
                style={{
                  background: `${d.color}10`,
                  border: `1px solid ${d.color}25`,
                  borderRadius: 8,
                  padding: "6px 14px",
                  fontFamily: FONT.body,
                  fontSize: 11,
                  fontWeight: 600,
                  color: d.color,
                  display: "flex",
                  alignItems: "center",
                  gap: 5,
                }}
              >
                <span>{d.icon}</span> {d.label}
              </div>
            ))}
          </div>

          <ArrowDown height={36} />

          <div
            style={{
              background: `${COLORS.monthly}08`,
              border: `1px dashed ${COLORS.monthly}30`,
              borderRadius: 10,
              padding: "10px 20px",
              fontFamily: FONT.mono,
              fontSize: 10,
              color: COLORS.monthly,
              textAlign: "center",
              maxWidth: 400,
            }}
          >
            Responses from core questions trigger adaptive branching below ↓
          </div>

          <ArrowDown height={36} />
        </div>

        {/* ──────── STAGE 4: Adaptive Branching Layer ──────── */}
        <StageHeader
          number="4"
          title="Adaptive Branching Layer"
          color={COLORS.branch}
          colorLight={COLORS.branchLight}
        />

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(270px, 1fr))",
            gap: 20,
            marginBottom: 32,
          }}
        >
          {/* ── A. Mental Health Branch ── */}
          <BranchPanel
            title="Mental Health"
            icon="🧠"
            color={COLORS.mental}
            colorLight={COLORS.mentalLight}
            triggerQuestion="In the past month, have you felt low in mood, sad, hopeless, nervous, worried, or restless?"
            decision="Concern indicated?"
            yesPath={[
              "Q1a: How often?",
              "Q1b: Difficulty managing life?",
              "Q1c: Feeling isolated?",
            ]}
            noPath={["Skip mental health follow-up", "Continue to next domain"]}
            deeperPath={{
              label: "Risk ≥ Moderate → Deeper Expansion",
              items: [
                "Impact on work/tasks/relationships",
                "Hard to enjoy usual activities",
                "Difficulty controlling worries",
                "Trouble relaxing / unwinding",
                "Feeling difficulties piling up",
                "Feeling no one to turn to",
              ],
            }}
            annotation="risk-based expansion"
          />

          {/* ── B. Physical Activity Branch ── */}
          <BranchPanel
            title="Physical Activity"
            icon="🏃"
            color={COLORS.physical}
            colorLight={COLORS.physicalLight}
            triggerQuestion="In the past month, did you do any moderate-intensity physical activity for at least 10 min continuously?"
            decision="Did activity?"
            yesPath={[
              "Q3a: Days per week?",
              "Q3b: Minutes per day?",
              "Then ask vigorous activity…",
            ]}
            noPath={["Skip to sedentary time (Q5)", "No detailed follow-up"]}
            deeperPath={{
              label: "If Vigorous = Yes → Sub-branch",
              items: [
                "Q4a: Days per week (vigorous)?",
                "Q4b: Minutes per day (vigorous)?",
              ],
            }}
            annotation="skip logic"
          />

          {/* ── C. Alcohol Branch ── */}
          <BranchPanel
            title="Alcohol"
            icon="🍷"
            color={COLORS.alcohol}
            colorLight={COLORS.alcoholLight}
            triggerQuestion="Do you consume alcoholic drinks? (from foundational baseline Q3)"
            decision="Consumes alcohol?"
            yesPath={[
              "Frequency of drinking",
              "Standard drinks per occasion",
              "5+ drinks on one occasion?",
            ]}
            noPath={["Skip entire alcohol path", "Move to next domain"]}
            deeperPath={{
              label: "Higher-risk pattern → AUDIT Expansion",
              items: [
                "Unable to stop once started?",
                "Failed obligations due to drinking?",
                "Morning drink needed?",
                "Guilt/remorse after drinking?",
                "Memory blackouts?",
                "Injury from drinking?",
              ],
            }}
            annotation="progressive disclosure"
          />

          {/* ── D. Women's Health Branch ── */}
          <BranchPanel
            title="Women's Health"
            icon="♀"
            color={COLORS.womens}
            colorLight={COLORS.womensLight}
            triggerQuestion="Eligibility check: Is the user female? (from foundational gender field)"
            decision="Eligible?"
            yesPath={[
              "Period symptoms affecting QoL?",
              "Pregnancy history",
              "Pregnancy complications?",
              "Menopause status",
              "Diagnosed conditions (PCOS, etc.)",
            ]}
            noPath={["Module completely hidden", "User never sees these questions"]}
            deeperPath={null}
            annotation="eligibility filtering"
          />

          {/* ── E. Dietary Branch ── */}
          <BranchPanel
            title="Dietary"
            icon="🥗"
            color={COLORS.dietary}
            colorLight={COLORS.dietaryLight}
            triggerQuestion="Core dietary questions asked monthly (water, fruit, vegetable intake)"
            decision="Monthly rotation"
            yesPath={[
              "Water intake (Q2)",
              "Fruit serves (Q2a)",
              "Vegetable serves (Q2b)",
              "+ Rotating items per month cycle",
            ]}
            noPath={["Rotation-based: not all shown each month"]}
            deeperPath={{
              label: "Rotating Question Sets (Month 1–12)",
              items: [
                "Spread/oil type, milk, soft drinks",
                "Eggs, sugar, cereal, bread",
                "Cooking oils, tea/coffee",
                "Food frequency (grain, dairy, meat, fish)",
              ],
            }}
            annotation="question rotation"
          />
        </div>

        {/* ── Merge indicator ── */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", marginBottom: 12 }}>
          <div
            style={{
              background: `${COLORS.branch}08`,
              border: `1px dashed ${COLORS.branch}30`,
              borderRadius: 10,
              padding: "10px 24px",
              fontFamily: FONT.mono,
              fontSize: 10,
              color: COLORS.branch,
              textAlign: "center",
            }}
          >
            All branch paths merge → Completion
          </div>
          <ArrowDown height={36} />
        </div>

        {/* ──────── STAGE 5: Completion ──────── */}
        <StageHeader
          number="5"
          title="Completion / Summary"
          color={COLORS.completion}
          colorLight={COLORS.completionLight}
        />

        <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
          <ScreenNode
            title="Assessment Complete"
            icon="✅"
            color={COLORS.completion}
            colorLight={COLORS.completionLight}
            items={[
              "Thank you / supportive completion message",
              "Summary of domains covered this session",
              "Next check-in reminder (monthly cycle)",
              "Optional: link to resources if flagged",
            ]}
            width={340}
          />

          {/* Risk flag note */}
          <div
            style={{
              marginTop: 16,
              display: "flex",
              gap: 12,
              flexWrap: "wrap",
              justifyContent: "center",
            }}
          >
            {[
              "If mental health risk ≥ moderate → show support resources",
              "If high-risk alcohol → show helpline links",
            ].map((note, i) => (
              <div
                key={i}
                style={{
                  background: "#FFF5F5",
                  border: "1px solid #F0D0D0",
                  borderRadius: 8,
                  padding: "6px 14px",
                  fontFamily: FONT.body,
                  fontSize: 10.5,
                  color: "#9B4040",
                  maxWidth: 300,
                }}
              >
                ⚠ {note}
              </div>
            ))}
          </div>
        </div>

        {/* ── Footer annotations summary ── */}
        <div
          style={{
            marginTop: 48,
            padding: "20px 24px",
            background: "#FFFFFF",
            border: `1px solid ${COLORS.border}`,
            borderRadius: 14,
          }}
        >
          <div
            style={{
              fontFamily: FONT.body,
              fontSize: 13,
              fontWeight: 600,
              color: COLORS.text,
              marginBottom: 12,
            }}
          >
            UX Patterns Used in This Flow
          </div>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
              gap: 10,
            }}
          >
            {[
              { pattern: "Skip Logic", desc: "Hide follow-ups when trigger answer is negative" },
              { pattern: "Risk-Based Expansion", desc: "Show deeper questions only for elevated risk" },
              { pattern: "Eligibility Filtering", desc: "Show/hide modules based on user profile" },
              { pattern: "Progressive Disclosure", desc: "Reveal complexity gradually based on need" },
              { pattern: "Question Rotation", desc: "Distribute questions across monthly cycles" },
              { pattern: "Adaptive Follow-up", desc: "Only ask relevant follow-ups based on answers" },
            ].map((p, i) => (
              <div
                key={i}
                style={{
                  display: "flex",
                  gap: 10,
                  alignItems: "flex-start",
                  padding: "8px 10px",
                  background: COLORS.annotationBg,
                  border: `1px solid ${COLORS.annotationBorder}`,
                  borderRadius: 8,
                }}
              >
                <div>
                  <div
                    style={{
                      fontFamily: FONT.mono,
                      fontSize: 10,
                      fontWeight: 600,
                      color: COLORS.annotationText,
                    }}
                  >
                    {p.pattern}
                  </div>
                  <div
                    style={{
                      fontFamily: FONT.body,
                      fontSize: 10.5,
                      color: COLORS.textMuted,
                      marginTop: 2,
                      lineHeight: 1.4,
                    }}
                  >
                    {p.desc}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
