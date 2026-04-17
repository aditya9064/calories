import { useState, useRef } from 'react'
import { useStore, entriesForDay, totalCalories } from '../store/useStore'
import { analyzeFood, fileToBase64 } from '../api/foodAnalyzer'

export default function FoodLog() {
  const { state, dispatch } = useStore()
  const [image, setImage] = useState(null)          // { file, url, base64 }
  const [analyzing, setAnalyzing] = useState(false)
  const [result, setResult] = useState(null)
  const [error, setError] = useState('')
  const [showManual, setShowManual] = useState(false)
  const fileRef = useRef()

  const todayFood = entriesForDay(state.foodEntries, new Date())
  const total = totalCalories(todayFood)

  async function handleFile(file) {
    if (!file) return
    const url = URL.createObjectURL(file)
    const base64 = await fileToBase64(file)
    setImage({ file, url, base64 })
    setResult(null)
    setError('')

    if (!state.apiKey) {
      setError('Add your OpenAI API key in Settings first.')
      return
    }
    setAnalyzing(true)
    try {
      const r = await analyzeFood(base64, state.apiKey)
      setResult(r)
    } catch (e) {
      setError(e.message)
    } finally {
      setAnalyzing(false)
    }
  }

  function logResult() {
    dispatch({
      type: 'ADD_FOOD',
      payload: {
        id: crypto.randomUUID(),
        name: result.name,
        calories: result.total_calories,
        protein: result.protein_g,
        carbs: result.carbs_g,
        fat: result.fat_g,
        imageUrl: image?.url,
        timestamp: new Date().toISOString(),
      },
    })
    setResult(null)
    setImage(null)
  }

  return (
    <div className="screen">
      <div className="screen-header">
        <span className="label">FOOD SCANNER</span>
        <span style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--blue)', background: 'rgba(51,146,255,0.1)', padding: '3px 8px', borderRadius: 4 }}>AI POWERED</span>
      </div>

      {/* Scanner card */}
      <div className="card">
        <label className="camera-area">
          {analyzing ? (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
              <div className="spinner" />
              <span style={{ fontFamily: 'var(--mono)', fontSize: 12, color: 'var(--green)' }}>ANALYZING...</span>
            </div>
          ) : image ? (
            <img src={image.url} alt="food" />
          ) : (
            <>
              <span style={{ fontSize: 40 }}>📸</span>
              <span>Tap to take photo or upload</span>
              <span style={{ fontSize: 11, color: 'var(--gray)' }}>AI will estimate calories</span>
            </>
          )}
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            capture="environment"
            onChange={e => handleFile(e.target.files[0])}
          />
        </label>

        {error && <p className="error-msg">{error}</p>}

        <div style={{ display: 'flex', gap: 10, marginTop: 12 }}>
          <button className="btn btn-secondary" onClick={() => { setImage(null); setResult(null); setError('') }}>
            Clear
          </button>
          <button className="btn btn-secondary" onClick={() => setShowManual(true)}>
            ✏️ Manual
          </button>
        </div>
      </div>

      {/* Result card */}
      {result && (
        <div className="result-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontWeight: 700, fontSize: 16 }}>{result.name}</div>
              <div style={{ fontSize: 11, color: 'var(--sub)', marginTop: 2 }}>
                Confidence: {Math.round((result.confidence || 0.8) * 100)}%
              </div>
            </div>
            <div>
              <span className={`ticker-value surplus`} style={{ fontSize: 32 }}>+{Math.round(result.total_calories)}</span>
              <span style={{ fontSize: 13, color: 'var(--green)', opacity: 0.7, marginLeft: 4 }}>kcal</span>
            </div>
          </div>

          <div className="macro-row">
            <span className="macro-tag p">P {Math.round(result.protein_g)}g</span>
            <span className="macro-tag c">C {Math.round(result.carbs_g)}g</span>
            <span className="macro-tag f">F {Math.round(result.fat_g)}g</span>
          </div>

          {result.breakdown && Object.keys(result.breakdown).length > 0 && (
            <>
              <hr />
              <div className="label" style={{ marginBottom: 8 }}>BREAKDOWN</div>
              {Object.entries(result.breakdown)
                .sort((a, b) => b[1] - a[1])
                .map(([item, cal]) => (
                  <div key={item} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 4 }}>
                    <span style={{ color: 'var(--sub)' }}>{item}</span>
                    <span style={{ fontFamily: 'var(--mono)', color: 'var(--green)', fontSize: 12 }}>{Math.round(cal)} kcal</span>
                  </div>
                ))
              }
            </>
          )}

          <button className="btn btn-primary" style={{ marginTop: 14 }} onClick={logResult}>
            LOG FOOD
          </button>
        </div>
      )}

      {/* Manual entry modal */}
      {showManual && <ManualEntry onClose={() => setShowManual(false)} />}

      {/* Today's log */}
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <span className="label">TODAY'S LOG</span>
          <span style={{ fontFamily: 'var(--mono)', fontSize: 12, color: 'var(--green)' }}>
            {Math.round(total).toLocaleString()} kcal
          </span>
        </div>

        {todayFood.length === 0
          ? <p className="empty">No food logged yet</p>
          : [...todayFood].reverse().map(f => (
            <div key={f.id} className="food-row">
              <div className="food-thumb">
                {f.imageUrl ? <img src={f.imageUrl} alt={f.name} /> : <span style={{ fontSize: 20 }}>🍽️</span>}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{f.name}</div>
                <div style={{ fontSize: 11, color: 'var(--sub)' }}>
                  P:{Math.round(f.protein)}g · C:{Math.round(f.carbs)}g · F:{Math.round(f.fat)}g
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontFamily: 'var(--mono)', fontSize: 14, color: 'var(--green)', fontWeight: 700 }}>
                  +{Math.round(f.calories)}
                </span>
                <button className="delete-btn" onClick={() => dispatch({ type: 'DELETE_FOOD', payload: f.id })}>×</button>
              </div>
            </div>
          ))
        }
      </div>

      {/* Workout log */}
      <WorkoutLogger />
    </div>
  )
}

function ManualEntry({ onClose }) {
  const { dispatch } = useStore()
  const [form, setForm] = useState({ name: '', calories: '', protein: '', carbs: '', fat: '' })

  function save() {
    if (!form.name || !form.calories) return
    dispatch({
      type: 'ADD_FOOD',
      payload: {
        id: crypto.randomUUID(),
        name: form.name,
        calories: parseFloat(form.calories) || 0,
        protein: parseFloat(form.protein) || 0,
        carbs: parseFloat(form.carbs) || 0,
        fat: parseFloat(form.fat) || 0,
        timestamp: new Date().toISOString(),
      },
    })
    onClose()
  }

  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)',
      display: 'flex', alignItems: 'flex-end', zIndex: 200
    }}>
      <div style={{ background: 'var(--panel)', borderRadius: '20px 20px 0 0', padding: 20, width: '100%', paddingBottom: 'calc(env(safe-area-inset-bottom) + 20px)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <span className="label">MANUAL ENTRY</span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--sub)', fontSize: 22, cursor: 'pointer' }}>×</button>
        </div>

        <Field label="Food Name" value={form.name} onChange={v => setForm(f => ({ ...f, name: v }))} placeholder="e.g. Chicken Salad" />
        <Field label="Calories (kcal)" value={form.calories} onChange={v => setForm(f => ({ ...f, calories: v }))} type="number" placeholder="0" />

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 16 }}>
          <SmallField label="Protein g" value={form.protein} onChange={v => setForm(f => ({ ...f, protein: v }))} />
          <SmallField label="Carbs g" value={form.carbs} onChange={v => setForm(f => ({ ...f, carbs: v }))} />
          <SmallField label="Fat g" value={form.fat} onChange={v => setForm(f => ({ ...f, fat: v }))} />
        </div>

        <button className="btn btn-primary" onClick={save} disabled={!form.name || !form.calories}>
          LOG FOOD
        </button>
      </div>
    </div>
  )
}

function WorkoutLogger() {
  const { state, dispatch } = useStore()
  const [show, setShow] = useState(false)
  const [form, setForm] = useState({ name: 'Running', calories: '', duration: '' })
  const todayWorkouts = entriesForDay(state.workoutEntries, new Date())

  function save() {
    dispatch({
      type: 'ADD_WORKOUT',
      payload: {
        id: crypto.randomUUID(),
        name: form.name,
        calories: parseFloat(form.calories) || 0,
        duration: parseFloat(form.duration) || 0,
        timestamp: new Date().toISOString(),
      },
    })
    setShow(false)
  }

  return (
    <div className="card">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <span className="label">LOG WORKOUT</span>
        <button className="btn btn-secondary" style={{ padding: '6px 14px', fontSize: 12 }} onClick={() => setShow(!show)}>
          + Add
        </button>
      </div>

      {show && (
        <div style={{ marginBottom: 12 }}>
          <div style={{ marginBottom: 8 }}>
            <select className="input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              style={{ background: 'var(--bg)', color: 'var(--text)', marginBottom: 8 }}>
              {['Running','Cycling','Walking','Swimming','HIIT','Strength Training','Yoga','Other'].map(w =>
                <option key={w}>{w}</option>
              )}
            </select>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 10 }}>
            <SmallField label="Calories burned" value={form.calories} onChange={v => setForm(f => ({ ...f, calories: v }))} />
            <SmallField label="Duration (min)" value={form.duration} onChange={v => setForm(f => ({ ...f, duration: v }))} />
          </div>
          <button className="btn btn-primary" style={{ fontSize: 13 }} onClick={save} disabled={!form.calories}>
            LOG WORKOUT
          </button>
        </div>
      )}

      {todayWorkouts.length === 0
        ? <p className="empty" style={{ padding: '8px 0' }}>No workouts today</p>
        : todayWorkouts.map(w => (
          <div key={w.id} className="food-row">
            <span style={{ fontSize: 22 }}>🏋️</span>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 14 }}>{w.name}</div>
              <div style={{ fontSize: 11, color: 'var(--sub)' }}>{w.duration} min</div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontFamily: 'var(--mono)', fontSize: 14, color: 'var(--red)', fontWeight: 700 }}>
                -{Math.round(w.calories)}
              </span>
              <button className="delete-btn" onClick={() => dispatch({ type: 'DELETE_WORKOUT', payload: w.id })}>×</button>
            </div>
          </div>
        ))
      }
    </div>
  )
}

function Field({ label, value, onChange, type = 'text', placeholder }) {
  return (
    <div style={{ marginBottom: 12 }}>
      <div className="label" style={{ marginBottom: 6 }}>{label}</div>
      <input className="input" type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} inputMode={type === 'number' ? 'decimal' : 'text'} />
    </div>
  )
}

function SmallField({ label, value, onChange }) {
  return (
    <div>
      <div className="label" style={{ marginBottom: 4, fontSize: 9 }}>{label}</div>
      <input className="input" type="number" inputMode="decimal" value={value}
        onChange={e => onChange(e.target.value)} placeholder="0"
        style={{ padding: '10px 8px', fontSize: 14 }} />
    </div>
  )
}
