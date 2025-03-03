# PulseBeam Task Tracker
A blockchain-based task tracker with integrated light and sound notification system for productivity.

## Features
- Create and manage tasks with deadlines
- Set notification preferences (light, sound, or both)
- Track task completion status 
- View task history and productivity metrics
- Customize notification settings

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Create a new task
(contract-call? .pulse-beam create-task "Complete project" u1683849600 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Set notification preferences
(contract-call? .pulse-beam set-notifications true true 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Mark task as complete
(contract-call? .pulse-beam complete-task u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
