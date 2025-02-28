;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-product-exists (err u101))
(define-constant err-product-not-found (err u102))
(define-constant err-not-owner (err u103))
(define-constant err-invalid-input (err u104))

;; Data structures
(define-map products
  { product-id: (string-ascii 64) }
  {
    owner: principal,
    manufacturer: principal,
    creation-date: uint,
    status: (string-ascii 20),
    metadata: (string-ascii 256)
  }
)

(define-map history
  { product-id: (string-ascii 64), sequence: uint }
  {
    previous-owner: principal,
    new-owner: principal,
    timestamp: uint,
    action: (string-ascii 20)
  }
)

;; Data variables
(define-data-var history-sequence uint u0)

;; Public functions
(define-public (register-product 
  (product-id (string-ascii 64))
  (metadata (string-ascii 256)))
  (begin
    (asserts! (> (len product-id) u0) err-invalid-input)
    (asserts! (> (len metadata) u0) err-invalid-input)
    (let ((exists (get-product-details product-id)))
      (asserts! (is-eq (is-ok exists) false) err-product-exists)
      (print {event: "product-registered", product-id: product-id, owner: tx-sender})
      (ok (map-set products
        { product-id: product-id }
        {
          owner: tx-sender,
          manufacturer: tx-sender,
          creation-date: block-height,
          status: "created",
          metadata: metadata
        }
      ))
    )
  )
)

(define-public (update-status
  (product-id (string-ascii 64))
  (new-status (string-ascii 20)))
  (let ((product (unwrap! (get-product-details product-id) err-product-not-found)))
    (asserts! (is-eq (get owner product) tx-sender) err-not-owner)
    (print {event: "status-updated", product-id: product-id, status: new-status})
    (ok (map-set products
      { product-id: product-id }
      (merge product { status: new-status })
    ))
  )
)

(define-public (transfer-ownership
  (product-id (string-ascii 64))
  (new-owner principal))
  (let ((product (unwrap! (get-product-details product-id) err-product-not-found)))
    (asserts! (is-eq (get owner product) tx-sender) err-not-owner)
    (print {event: "ownership-transferred", product-id: product-id, from: tx-sender, to: new-owner})
    (map-set products
      { product-id: product-id }
      (merge product { owner: new-owner })
    )
    (record-history product-id tx-sender new-owner "transfer")
    (ok true)
  )
)

;; Private functions
(define-private (record-history
  (product-id (string-ascii 64))
  (previous-owner principal)
  (new-owner principal)
  (action (string-ascii 20)))
  (begin
    (var-set history-sequence (+ (var-get history-sequence) u1))
    (map-set history
      { product-id: product-id, sequence: (var-get history-sequence) }
      {
        previous-owner: previous-owner,
        new-owner: new-owner,
        timestamp: block-height,
        action: action
      }
    )
  )
)

;; Read only functions
(define-read-only (get-product-details (product-id (string-ascii 64)))
  (map-get? products { product-id: product-id })
)

(define-read-only (get-history-entry (product-id (string-ascii 64)) (sequence uint))
  (map-get? history { product-id: product-id, sequence: sequence })
)

(define-read-only (get-history-sequence) 
  (var-get history-sequence)
)
