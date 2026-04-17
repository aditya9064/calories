import { useStore, entriesForDay, totalCalories } from '../store/useStore'

export default function Dashboard() {
  const { state } = useStore()
  const today = new Date()
  const todayFood = entriesForDay(state.foodEntries, today)
  const todayWorkouts = entriesForDay(state.workoutEntries, today)

  const consumed = totalCalories(todayFood)
  const burned = totalCalories(todayWorkouts)
  const net = consumed - burned
  const surplus = net > 0
  const pct = burned > 0 ? ((Math.abs(net) / burned) * 100).toFixed(1) : '0.0'

  return (
    <div className="screen">
      <div className="screen-header">
        <div>
          <div className="label">CALORIE TRADER</div>
          <div style={{ fontSize: 13, color: 'var(--sub)', marginTop: 2 }}>
            {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })}
          </div>
        </div>
        <div className="live-dot">LIVE</div>
      </div>

      {/* Main ticker card */}
      <div className="card" style={{ borderColor: surplus ? 'rgba(24,215,104,0.25)' : 'rgba(242,54,69,0.25)' }}>
        <div className="label">NET CALORIES TODAY</div>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', marginTop: 8 }}>
          <div>
            <span className={`ticker-value ${surplus ? 'surplus' : 'deficit'}`} style={{ fontSize: 52 }}>
              {surplus ? '+' : ''}{Math.round(net).toLocaleString()}
            </span>
            <span style={{ fontSize: 16, color: surplus ? 'var(--green)' : 'var(--red)', marginLeft: 6, opacity: 0.7 }}>kcal</span>
          </div>
          <div className={`badge ${surplus ? 'surplus' : 'deficit'}`}>
            {surplus ? '▲' : '▼'} {pct}%
          </div>
        </div>

        {/* mini bar */}
        <div style={{ height: 6, borderRadius: 3, background: 'rgba(255,255,255,0.06)', marginTop: 14, overflow: 'hidden' }}>
          <div style={{
            height: '100%',
            borderRadius: 3,
            width: `${Math.min(100, (Math.abs(net) / 1000) * 100)}%`,
            background: surplus
              ? 'linear-gradient(90deg, var(--green), rgba(24,215,104,0.3))'
              : 'linear-gradient(90deg, var(--red), rgba(242,54,69,0.3))',
            transition: 'width 0.6s ease'
          }} />
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
          <span style={{ fontSize: 11, color: 'var(--gray)' }}>0</span>
          <span style={{ fontSize: 11, color: surplus ? 'var(--green)' : 'var(--red)', fontFamily: 'var(--mono)' }}>
            {surplus ? 'SURPLUS' : 'DEFICIT'}
          </span>
          <span style={{ fontSize: 11, color: 'var(--gray)' }}>1000+</span>
        </div>
      </div>

      {/* Metrics */}
      <div className="metrics-row">
        <MetricTile label="CONSUMED" value={Math.round(consumed)} unit="kcal" color="var(--text)" />
        <MetricTile label="BURNED" value={Math.round(burned)} unit="kcal" color="var(--red)" />
        <MetricTile label="NET" value={Math.round(net)} unit="kcal" color={surplus ? 'var(--green)' : 'var(--red)'} />
      </div>

      {/* Goal progress */}
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
          <span className="label">CALORIE GOAL</span>
          <span style={{ fontFamily: 'var(--mono)', fontSize: 13, color: 'var(--green)' }}>
            {Math.round(consumed).toLocaleString()} / {state.calorieGoal.toLocaleString()} kcal
          </span>
        </div>
        <div style={{ height: 8, borderRadius: 4, background: 'rgba(255,255,255,0.06)', overflow: 'hidden' }}>
          <div style={{
            height: '100%',
            borderRadius: 4,
            width: `${Math.min(100, (consumed / state.calorieGoal) * 100)}%`,
            background: consumed > state.calorieGoal
              ? 'var(--red)'
              : 'linear-gradient(90deg, var(--green), #0fb856)',
            transition: 'width 0.6s ease'
          }} />
        </div>
      </div>

      {/* Workouts */}
      <div className="card">
        <div className="label" style={{ marginBottom: 10 }}>WORKOUTS TODAY</div>
        {todayWorkouts.length === 0
          ? <p className="empty">No workouts logged today</p>
          : todayWorkouts.map(w => (
            <div key={w.id} className="food-row">
              <div className="food-thumb" style={{ fontSize: 22 }}>🏋️</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{w.name}</div>
                <div style={{ fontSize: 11, color: 'var(--sub)' }}>{w.duration} min</div>
              </div>
              <div style={{ fontFamily: 'var(--mono)', fontSize: 14, color: 'var(--red)', fontWeight: 700 }}>
                -{Math.round(w.calories)} kcal
              </div>
            </div>
          ))
        }
      </div>

      {/* Recent food */}
      <div className="card">
        <div className="label" style={{ marginBottom: 10 }}>RECENT FOOD</div>
        {todayFood.length === 0
          ? <p className="empty">No food logged today</p>
          : [...todayFood].reverse().slice(0, 4).map(f => (
            <div key={f.id} className="food-row">
              <div className="food-thumb">
                {f.imageUrl
                  ? <img src={f.imageUrl} alt={f.name} />
                  : <span style={{ fontSize: 20 }}>🍽️</span>
                }
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{f.name}</div>
                <div style={{ fontSize: 11, color: 'var(--sub)' }}>
                  {new Date(f.timestamp).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                </div>
              </div>
              <div style={{ fontFamily: 'var(--mono)', fontSize: 14, color: 'var(--green)', fontWeight: 700 }}>
                +{Math.round(f.calories)}
              </div>
            </div>
          ))
        }
      </div>
    </div>
  )
}

function MetricTile({ label, value, unit, color }) {
  return (
    <div className="metric-tile">
      <div className="label">{label}</div>
      <div className="val" style={{ color }}>{value.toLocaleString()}</div>
      <div className="unit">{unit}</div>
    </div>
  )
}
