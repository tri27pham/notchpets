import { PET_SLOT_WIDTH, PET_SLOT_HEIGHT } from '../shared/constants'

export default function PetSlot() {
  return (
    <div className="pet-slot" style={{ width: PET_SLOT_WIDTH, height: PET_SLOT_HEIGHT }}>
      <div style={{ width: 32, height: 32, background: '#ffffff' }} />
    </div>
  )
}
