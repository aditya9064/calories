import { useState } from 'react'
import {
  Chart as ChartJS, CategoryScale, LinearScale,
  BarElement, Tooltip, Legend
} from 'chart.js'
import { Bar } from 'react-chartjs-2'
import { useStore, entriesForDay, totalCalories, pastDays } from '../store/useStore'

ChartJS.register(CategoryScale, LinearScale, BarElement, Tooltip, Legend)

const PERIODS = [
  { label: '1D', days: 1 },
  { label: '1W', days: 7 },
  { label: '1M', days: 30 },
]

export default function Summary() {
  const { state } = useStore()
  const [period, setPeriod] = useState(1)   // index into PERIODS

  const days = pastDays(PERIODS[period].days)

  const summaries = days.map(date => {
    const consumed = totalCalories(entriesForDay(state.foodEntries, date))
    const burned = totalCalories(entriesForDay(state.workoutEntries, date))
    const bmr = state.bmr
    const net = consumed - burned - bmr
    return { date, consumed, burned, bmr, net, surplus: net > 0 }
  })

  const totalNet = summaries.reduce((s, d) => s + d.net, 0)
  const avgNet = summaries.length ? totalNet / summaries.length : 0
  const surplusDays = summaries.filter(d => d.surplus).length
  const deficitDays = summaries.length - surplusDays
  const overallSurplus = totalNet > 0

  const chartData = {
    labels: summaries.map(d =>
      d.date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    ),
    datasets: [
      {
        label: 'Net Calories',
        data: summaries.map(d => Math.round(d.net)),
        backgroundColor: summaries.map(d => d.surplus ? 'rgba(24,215,104,0.75)' : 'rgba(242,54,69,0.75)'),
        borderRadius: 4,
        borderSkipped: false,
      },
    ],
  }

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: '#1c1e26',
        titleColor: '#9ca3af',
        bodyColor: '#e8eaf0',
        callbacks: {
          label: ctx => {
            const v = ctx.raw
            return ` ${v > 0 ? '+' : ''}${v.toLocaleString()} kcal`
          },
        },
      },
    },
    scales: {
      x: {
        ticks: { color: '#6b7280', font: { size: 10 } },
        grid: { color: 'rgba(255,255,255,0.04)' },
      },
      y: {
        ticks: { color: '#6b7280', font: { size: 10 } },
        grid: { color: 'rgba(255,255,255,0.04)' },
      },
    },
  }

  return (
    <div className="screen">
      <div className="screen-header">
        <span className="label">PORTFOLIO SUMMARY</span>
        <div className="period-pills">
          {PERIODS.map((p, i) => (
            <button key={p.label} className={`period-pill ${period === i ? 'active' : ''}`} onClick={() => setPeriod(i)}>
              {p.label}
            </button>
          ))}
        </div>
      </div>

      {/* Summary hero */}
      <div className="card" style={{ borderColor: overallSurplus ? 'rgba(24,215,104,0.25)' : 'rgba(242,54,69,0.25)' }}>
        <div className="label">{PERIODS[period].label === '1D' ? 'TODAY' : PERIODS[period].label === '1W' ? 'THIS WEEK' : 'THIS MONTH'}</div>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', marginTop: 8, flexWrap: 'wrap', gap: 8 }}>
          <div>
            <span className={`ticker-value ${overallSurplus ? 'surplus' : 'deficit'}`} style={{ fontSize: 44 }}>
              {overallSurplus ? '+' : ''}{Math.round(totalNet).toLocaleString()}
            </span>
            <span style={{ fontSize: 14, marginLeft: 5, opacity: 0.7, color: overallSurplus ? 'var(--green)' : 'var(--red)' }}>kcal net</span>
          </div>
          <div className={`badge ${overallSurplus ? 'surplus' : 'deficit'}`} style={{ fontSize: 14 }}>
            {overallSurplus ? '▲ SURPLUS' : '▼ DEFICIT'}
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginTop: 16 }}>
          <StatBox label="AVG/DAY" value={(avgNet > 0 ? '+' : '') + Math.round(avgNet)} color={avgNet > 0 ? 'var(--green)' : 'var(--red)'} />
          <StatBox label="SURPLUS DAYS" value={surplusDays} color="var(--green)" />
          <StatBox label="DEFICIT DAYS" value={deficitDays} color="var(--red)" />
        </div>
      </div>

      {/* Chart */}
      <div className="card">
        <div className="label" style={{ marginBottom: 12 }}>NET CALORIE CHART</div>
        <div className="chart-wrap">
          <Bar data={chartData} options={chartOptions} />
        </div>
      </div>

      {/* Day breakdown */}
      <div className="card">
        <div className="label" style={{ marginBottom: 12 }}>DAILY BREAKDOWN</div>
        {[...summaries].reverse().map((d, i) => (
          <DayRow key={i} summary={d} />
        ))}
      </div>
    </div>
  )
}

function StatBox({ label, value, color }) {
  return (
    <div style={{ background: 'rgba(255,255,255,0.04)', borderRadius: 8, padding: '10px 8px', textAlign: 'center' }}>
      <div className="label" style={{ fontSize: 8, marginBottom: 4 }}>{label}</div>
      <div style={{ fontFamily: 'var(--mono)', fontSize: 16, fontWeight: 700, color }}>{value}</div>
    </div>
  )
}

function DayRow({ summary }) {
  const [expanded, setExpanded] = useState(false)
  const isToday = new Date().toDateString() === summary.date.toDateString()
  const color = summary.surplus ? 'var(--green)' : 'var(--red)'

  return (
    <div style={{ marginBottom: 6 }}>
      <button
        onClick={() => setExpanded(e => !e)}
        style={{ width: '100%', background: 'rgba(255,255,255,0.03)', border: 'none', borderRadius: 8, cursor: 'pointer', padding: 0 }}
      >
        <div className="day-row">
          <div style={{ textAlign: 'left' }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text)' }}>
              {summary.date.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })}
            </div>
            {isToday && <div style={{ fontSize: 9, color: 'var(--yellow)', fontFamily: 'var(--mono)', marginTop: 2 }}>TODAY</div>}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div className={`badge ${summary.surplus ? 'surplus' : 'deficit'}`} style={{ fontSize: 13 }}>
              {summary.surplus ? '▲' : '▼'} {summary.surplus ? '+' : ''}{Math.round(summary.net).toLocaleString()}
            </div>
            <span style={{ color: 'var(--gray)', fontSize: 12 }}>{expanded ? '▲' : '▼'}</span>
          </div>
        </div>
      </button>

      {expanded && (
        <div style={{ padding: '10px 12px', background: 'rgba(255,255,255,0.02)', borderRadius: '0 0 8px 8px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          <MiniStat label="CONSUMED" value={Math.round(summary.consumed)} color="var(--text)" />
          <MiniStat label="BURNED" value={Math.round(summary.burned)} color="var(--red)" />
          <MiniStat label="BMR" value={Math.round(summary.bmr)} color="var(--blue)" />
        </div>
      )}
    </div>
  )
}

function MiniStat({ label, value, color }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <div className="label" style={{ fontSize: 8 }}>{label}</div>
      <div style={{ fontFamily: 'var(--mono)', fontSize: 14, fontWeight: 700, color, marginTop: 3 }}>
        {value.toLocaleString()}
      </div>
    </div>
  )
}
