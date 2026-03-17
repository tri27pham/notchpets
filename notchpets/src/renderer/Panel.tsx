import { useEffect, useRef } from 'react'
import PetSlot from './PetSlot'
import { COLLAPSE_DEBOUNCE_MS } from '../shared/constants'

export default function Panel() {
  const collapseTimer = useRef<ReturnType<typeof setTimeout> | null>(null)

  function handleMouseEnter() {
    if (collapseTimer.current !== null) {
      clearTimeout(collapseTimer.current)
      collapseTimer.current = null
    }
    window.ipcRenderer.send('panel:expand')
  }

  function handleMouseLeave() {
    collapseTimer.current = setTimeout(() => {
      window.ipcRenderer.send('panel:collapse')
    }, COLLAPSE_DEBOUNCE_MS)
  }

  useEffect(() => {
    return () => {
      if (collapseTimer.current !== null) clearTimeout(collapseTimer.current)
    }
  }, [])

  return (
    <div className="panel" onMouseEnter={handleMouseEnter} onMouseLeave={handleMouseLeave}>
      <PetSlot />
      <PetSlot />
    </div>
  )
}
