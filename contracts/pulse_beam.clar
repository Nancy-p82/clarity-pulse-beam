;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-UNAUTHORIZED (err u101))
(define-constant ERR-INVALID-TIME (err u102))
(define-constant ERR-INVALID-INPUT (err u103))
(define-constant ERR-TASK-LOCKED (err u104))

;; Data structures
(define-map tasks
  { task-id: uint }
  {
    description: (string-ascii 256),
    deadline: uint,
    completed: bool,
    owner: principal,
    priority: uint,
    category: (optional (string-ascii 64)),
    created-at: uint,
    last-modified: uint
  }
)

(define-map notification-prefs
  { user: principal }
  {
    light-enabled: bool,
    sound-enabled: bool
  }
)

(define-map task-history
  { task-id: uint, timestamp: uint }
  {
    action: (string-ascii 12),
    performer: principal
  }
)

;; Data variables
(define-data-var task-counter uint u0)

;; Events
(define-data-var last-event-id uint u0)

(define-map events
  { event-id: uint }
  {
    event-type: (string-ascii 24),
    task-id: uint,
    performer: principal,
    timestamp: uint
  }
)

;; Private functions
(define-private (is-owner (task-id uint) (user principal))
  (let ((task (unwrap! (map-get? tasks {task-id: task-id}) false)))
    (is-eq (get owner task) user)
  )
)

(define-private (log-event (event-type (string-ascii 24)) (task-id uint) (performer principal))
  (let ((event-id (+ (var-get last-event-id) u1)))
    (map-set events
      {event-id: event-id}
      {
        event-type: event-type,
        task-id: task-id,
        performer: performer,
        timestamp: block-height
      }
    )
    (var-set last-event-id event-id)
    event-id
  )
)

;; Public functions
(define-public (create-task (description (string-ascii 256)) (deadline uint) (owner principal) (priority uint) (category (optional (string-ascii 64))))
  (let (
    (task-id (+ (var-get task-counter) u1))
    (current-height block-height)
  )
    (asserts! (> deadline current-height) ERR-INVALID-TIME)
    (asserts! (<= priority u3) ERR-INVALID-INPUT)
    
    (map-set tasks
      {task-id: task-id}
      {
        description: description,
        deadline: deadline,
        completed: false,
        owner: owner,
        priority: priority,
        category: category,
        created-at: current-height,
        last-modified: current-height
      }
    )
    (var-set task-counter task-id)
    (log-event "task-created" task-id tx-sender)
    (ok task-id)
  )
)

(define-public (update-task (task-id uint) (description (string-ascii 256)) (deadline uint) (priority uint) (category (optional (string-ascii 64))))
  (let ((current-height block-height))
    (asserts! (is-owner task-id tx-sender) ERR-UNAUTHORIZED)
    (asserts! (> deadline current-height) ERR-INVALID-TIME)
    (asserts! (<= priority u3) ERR-INVALID-INPUT)
    
    (match (map-get? tasks {task-id: task-id})
      task (begin
        (map-set tasks
          {task-id: task-id}
          (merge task {
            description: description,
            deadline: deadline,
            priority: priority,
            category: category,
            last-modified: current-height
          })
        )
        (log-event "task-updated" task-id tx-sender)
        (ok true)
      )
      ERR-NOT-FOUND
    )
  )
)

(define-public (complete-task (task-id uint))
  (if (is-owner task-id tx-sender)
    (begin
      (match (map-get? tasks {task-id: task-id})
        task (begin
          (map-set tasks
            {task-id: task-id}
            (merge task {
              completed: true,
              last-modified: block-height
            })
          )
          (log-event "task-completed" task-id tx-sender)
          (ok true)
        )
        ERR-NOT-FOUND
      )
    )
    ERR-UNAUTHORIZED
  )
)

(define-public (delete-task (task-id uint))
  (if (is-owner task-id tx-sender)
    (begin
      (map-delete tasks {task-id: task-id})
      (log-event "task-deleted" task-id tx-sender)
      (ok true)
    )
    ERR-UNAUTHORIZED
  )
)

(define-public (set-notifications (light-enabled bool) (sound-enabled bool))
  (begin
    (map-set notification-prefs
      {user: tx-sender}
      {
        light-enabled: light-enabled,
        sound-enabled: sound-enabled
      }
    )
    (ok true)
  )
)

;; Read only functions
(define-read-only (get-task (task-id uint))
  (map-get? tasks {task-id: task-id})
)

(define-read-only (get-notifications (user principal))
  (default-to
    {light-enabled: false, sound-enabled: false}
    (map-get? notification-prefs {user: user})
  )
)

(define-read-only (get-task-history (task-id uint))
  (map-get? task-history {task-id: task-id})
)
