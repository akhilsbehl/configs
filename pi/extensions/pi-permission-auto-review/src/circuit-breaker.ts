const MAX_CONSECUTIVE_DENIALS = 3
const RECENT_WINDOW_SIZE = 50
const MAX_RECENT_DENIALS = 10

export class DenialCircuitBreaker {
  private consecutiveDenials = 0
  private recentDenials: boolean[] = []

  isOpen(): boolean {
    return (
      this.consecutiveDenials >= MAX_CONSECUTIVE_DENIALS ||
      this.recentDenials.filter(Boolean).length >= MAX_RECENT_DENIALS
    )
  }

  recordDenied(): void {
    this.consecutiveDenials += 1
    this.recordRecent(true)
  }

  recordNonDenial(): void {
    this.consecutiveDenials = 0
    this.recordRecent(false)
  }

  resetTurn(): void {
    this.consecutiveDenials = 0
    this.recentDenials = []
  }

  private recordRecent(denied: boolean): void {
    this.recentDenials.push(denied)
    if (this.recentDenials.length > RECENT_WINDOW_SIZE) {
      this.recentDenials.shift()
    }
  }
}
