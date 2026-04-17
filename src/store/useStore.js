import { createContext, useContext, useReducer, useEffect } from 'react'

const STORAGE_KEY = 'calorie_trader_v1'

const defaultState = {
  foodEntries: [],
  workoutEntries: [],
  calorieGoal: 2000,
  bmr: 1800,
  apiKey: '',
}

function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? { ...defaultState, ...JSON.parse(raw) } : defaultState
  } catch {
    return defaultState
  }
}

function reducer(state, action) {
  switch (action.type) {
    case 'ADD_FOOD':
      return { ...state, foodEntries: [...state.foodEntries, action.payload] }
    case 'DELETE_FOOD':
      return { ...state, foodEntries: state.foodEntries.filter(e => e.id !== action.payload) }
    case 'ADD_WORKOUT':
      return { ...state, workoutEntries: [...state.workoutEntries, action.payload] }
    case 'DELETE_WORKOUT':
      return { ...state, workoutEntries: state.workoutEntries.filter(e => e.id !== action.payload) }
    case 'SET_GOAL':
      return { ...state, calorieGoal: action.payload }
    case 'SET_BMR':
      return { ...state, bmr: action.payload }
    case 'SET_API_KEY':
      return { ...state, apiKey: action.payload }
    default:
      return state
  }
}

const StoreContext = createContext(null)

export function StoreProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, null, load)

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
  }, [state])

  return <StoreContext.Provider value={{ state, dispatch }}>{children}</StoreContext.Provider>
}

export function useStore() {
  return useContext(StoreContext)
}

// ── helpers ──────────────────────────────────────────────────────────────────

export function startOfDay(date = new Date()) {
  const d = new Date(date)
  d.setHours(0, 0, 0, 0)
  return d
}

export function isSameDay(a, b) {
  return startOfDay(a).getTime() === startOfDay(b).getTime()
}

export function entriesForDay(entries, date) {
  return entries.filter(e => isSameDay(new Date(e.timestamp), date))
}

export function totalCalories(entries) {
  return entries.reduce((s, e) => s + (e.calories || 0), 0)
}

export function pastDays(n) {
  return Array.from({ length: n }, (_, i) => {
    const d = new Date()
    d.setDate(d.getDate() - (n - 1 - i))
    d.setHours(0, 0, 0, 0)
    return d
  })
}
