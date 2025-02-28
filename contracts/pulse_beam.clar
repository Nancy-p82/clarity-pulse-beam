;; Constants
(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-UNAUTHORIZED (err u101))
(define-constant ERR-INVALID-TIME (err u102))

;; Data structures
(define-map tasks
  { task-id: uint }
  {
    description: (string-ascii 256),
    deadline: uint,
    completed: bool,
    owner: principal
  }
)

(define-map notification-prefs
  { user: principal }
  {
    light-enabled: bool,
    sound-enabled: bool
  }
)

;; Data variables
(define-data-var task-counter uint u0)

;; Private functions
(define-private (is-owner (task-id uint) (user principal))
  (let ((task (unwrap! (map-get? tasks {task-id: task-id}) false)))
    (is-eq (get owner task) user)
  )
)

;; Public functions
(define-public (create-task (description (string-ascii 256)) (deadline uint) (owner principal))
  (let ((task-id (+ (var-get task-counter) u1)))
    (if (> deadline (unwrap-panic (get-block-info? time)))
      (begin
        (map-set tasks
          {task-id: task-id}
          {
            description: description,
            deadline: deadline,
            completed: false,
            owner: owner
          }
        )
        (var-set task-counter task-id)
        (ok task-id)
      )
      ERR-INVALID-TIME
    )
  )
)

(define-public (complete-task (task-id uint) (user principal))
  (if (is-owner task-id user)
    (begin
      (match (map-get? tasks {task-id: task-id})
        task (begin
          (map-set tasks
            {task-id: task-id}
            (merge task {completed: true})
          )
          (ok true)
        )
        ERR-NOT-FOUND
      )
    )
    ERR-UNAUTHORIZED
  )
)

(define-public (set-notifications (light-enabled bool) (sound-enabled bool) (user principal))
  (begin
    (map-set notification-prefs
      {user: user}
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
