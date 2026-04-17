import { useState } from 'react'
import { useStore } from '../store/useStore'

export default function Settings() {
  const { state, dispatch } = useStore()
  const [apiKey, setApiKey] = useState(state.apiKey)
  const [goal, setGoal] = useState(String(state.calorieGoal))
  const [bmr, setBmr] = useState(String(state.bmr))
  const [saved, setSaved] = useState(false)

  function save() {
    dispatch({ type: 'SET_API_KEY', payload: apiKey.trim() })
    dispatch({ type: 'SET_GOAL', payload: parseFloat(goal) || 2000 })
    dispatch({ type: 'SET_BMR', payload: parseFloat(bmr) || 1800 })
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <div className="screen">
      <div className="screen-header">
        <span className="label">SETTINGS</span>
        {saved && (
          <span style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--green)' }}>✓ SAVED</span>
        )}
      </div>

      {/* AI */}
      <div className="card">
        <div className="label" style={{ marginBottom: 14 }}>AI FOOD ANALYSIS</div>

        <div style={{ marginBottom: 12 }}>
          <div className="label" style={{ marginBottom: 6 }}>OPENAI API KEY</div>
          <input
            className="input"
            type="password"
            value={apiKey}
            onChange={e => setApiKey(e.target.value)}
            placeholder="sk-..."
            autoComplete="off"
          />
          <p style={{ fontSize: 11, color: 'var(--gray)', marginTop: 6 }}>
            Required for photo-based calorie analysis (GPT-4o vision). Get yours at platform.openai.com
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 12px', background: 'rgba(255,255,255,0.03)', borderRadius: 8 }}>
          <span style={{ fontSize: 16 }}>{apiKey ? '🟢' : '🔴'}</span>
          <span style={{ fontSize: 13, color: apiKey ? 'var(--green)' : 'var(--red)' }}>
            {apiKey ? 'API key configured' : 'No API key — photo analysis disabled'}
          </span>
        </div>
      </div>

      {/* Goals */}
      <div className="card">
        <div className="label" style={{ marginBottom: 14 }}>GOALS & METABOLISM</div>

        <div style={{ marginBottom: 14 }}>
          <div className="label" style={{ marginBottom: 6 }}>DAILY CALORIE GOAL (kcal)</div>
          <input className="input" type="number" inputMode="decimal" value={goal} onChange={e => setGoal(e.target.value)} placeholder="2000" />
          <p style={{ fontSize: 11, color: 'var(--gray)', marginTop: 4 }}>
            Calories you aim to eat per day
          </p>
        </div>

        <div>
          <div className="label" style={{ marginBottom: 6 }}>RESTING BMR (kcal)</div>
          <input className="input" type="number" inputMode="decimal" value={bmr} onChange={e => setBmr(e.target.value)} placeholder="1800" />
          <p style={{ fontSize: 11, color: 'var(--gray)', marginTop: 4 }}>
            Calories your body burns at rest. Use a BMR calculator or Apple Health estimate.
          </p>
        </div>
      </div>

      {/* How net is calculated */}
      <div className="card">
        <div className="label" style={{ marginBottom: 10 }}>HOW NET IS CALCULATED</div>
        <FormulaRow label="Consumed" sign="+" color="var(--green)" />
        <FormulaRow label="Active calories burned" sign="−" color="var(--red)" />
        <FormulaRow label="BMR (resting burn)" sign="−" color="var(--blue)" />
        <hr />
        <FormulaRow label="Net calories" sign="=" color="var(--text)" bold />
        <p style={{ fontSize: 12, color: 'var(--gray)', marginTop: 8 }}>
          Green = surplus · Red = deficit
        </p>
      </div>

      {/* Note on HealthKit */}
      <div className="card" style={{ borderColor: 'rgba(245,204,27,0.2)' }}>
        <div className="label" style={{ marginBottom: 8, color: 'var(--yellow)' }}>⚠ APPLE HEALTH</div>
        <p style={{ fontSize: 13, color: 'var(--sub)', lineHeight: 1.6 }}>
          As a PWA, this app cannot read from Apple Health directly. Log workouts manually or use the burned-calories field above. A native iOS version with HealthKit sync is also available in this repository.
        </p>
      </div>

      <button className="btn btn-primary" onClick={save}>
        SAVE SETTINGS
      </button>
    </div>
  )
}

function FormulaRow({ label, sign, color, bold }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px solid var(--border)' }}>
      <span style={{ fontSize: 13, color: 'var(--sub)', fontWeight: bold ? 700 : 400 }}>{label}</span>
      <span style={{ fontFamily: 'var(--mono)', fontSize: 15, fontWeight: 700, color }}>{sign}</span>
    </div>
  )
}
