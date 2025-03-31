;; ========================================================================
;; FundSteps: Milestone-Based Crowdfunding On The Blockchain
;; ========================================================================

;; ========================================================================
;; Constants
;; ========================================================================
;; FundSteps: Contract constants for access control and error handling
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u201))
(define-constant ERR-MILESTONE-NOT-APPROVED (err u202))
(define-constant ERR-CAMPAIGN-ENDED (err u203))
(define-constant ERR-INVALID-MILESTONE (err u204))

;; ========================================================================
;; Data Maps
;; ========================================================================
;; FundSteps: Data structure for campaign information
(define-map Campaigns
  { campaign-id: uint }
  {
    owner: principal,
    total-goal: uint,
    total-funded: uint,
    end-height: uint,
    active: bool
  }
)

;; FundSteps: Data structure for campaign milestone tracking
(define-map Milestones
  { campaign-id: uint, milestone-id: uint }
  {
    amount: uint,
    description: (string-ascii 100),
    approved: bool,
    completed: bool
  }
)

;; FundSteps: Data structure for tracking contributor activity
(define-map Contributions
  { campaign-id: uint, contributor: principal }
  { amount: uint }
)

;; FundSteps: Campaign counter for generating unique campaign IDs
(define-data-var campaign-counter uint u0)

;; ========================================================================
;; Campaign Management Functions
;; ========================================================================
;; FundSteps: Create a new milestone-based crowdfunding campaign
(define-public (create-campaign (total-goal uint) (duration uint) (milestone-amounts (list 3 uint)) (milestone-descs (list 3 (string-ascii 100))))
  (let
    (
      (campaign-id (+ (var-get campaign-counter) u1))
      (end-height (+ block-height duration))
    )
    (var-set campaign-counter campaign-id)
    (map-insert Campaigns
      { campaign-id: campaign-id }
      {
        owner: tx-sender,
        total-goal: total-goal,
        total-funded: u0,
        end-height: end-height,
        active: true
      }
    )
    (map-insert Milestones { campaign-id: campaign-id, milestone-id: u1 } { amount: (unwrap-panic (element-at milestone-amounts u0)), description: (unwrap-panic (element-at milestone-descs u0)), approved: false, completed: false })
    (map-insert Milestones { campaign-id: campaign-id, milestone-id: u2 } { amount: (unwrap-panic (element-at milestone-amounts u1)), description: (unwrap-panic (element-at milestone-descs u1)), approved: false, completed: false })
    (map-insert Milestones { campaign-id: campaign-id, milestone-id: u3 } { amount: (unwrap-panic (element-at milestone-amounts u2)), description: (unwrap-panic (element-at milestone-descs u2)), approved: false, completed: false })
    (ok campaign-id)
  )
)

;; ========================================================================
;; Contribution Functions
;; ========================================================================
;; FundSteps: Contribute funds to a campaign
(define-public (contribute (campaign-id uint) (amount uint))
  (let
    (
      (campaign (unwrap! (map-get? Campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
    )
    (asserts! (get active campaign) ERR-CAMPAIGN-ENDED)
    (asserts! (< block-height (get end-height campaign)) ERR-CAMPAIGN-ENDED)
    
    (match (map-get? Contributions { campaign-id: campaign-id, contributor: tx-sender })
      contribution
      (map-set Contributions
        { campaign-id: campaign-id, contributor: tx-sender }
        { amount: (+ (get amount contribution) amount) })
      (map-insert Contributions
        { campaign-id: campaign-id, contributor: tx-sender }
        { amount: amount })
    )
    
    (map-set Campaigns
      { campaign-id: campaign-id }
      (merge campaign { total-funded: (+ (get total-funded campaign) amount) })
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok true)
  )
)

;; ========================================================================
;; Milestone Management Functions
;; ========================================================================
;; FundSteps: Approve a campaign milestone
(define-public (approve-milestone (campaign-id uint) (milestone-id uint))
  (let
    (
      (campaign (unwrap! (map-get? Campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (milestone (unwrap! (map-get? Milestones { campaign-id: campaign-id, milestone-id: milestone-id }) ERR-INVALID-MILESTONE))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (get active campaign) ERR-CAMPAIGN-ENDED)
    (map-set Milestones
      { campaign-id: campaign-id, milestone-id: milestone-id }
      (merge milestone { approved: true })
    )
    (ok true)
  )
)

;; ========================================================================
;; Read-Only Functions
;; ========================================================================
;; FundSteps: Get campaign details
(define-read-only (get-campaign (campaign-id uint))
  (map-get? Campaigns { campaign-id: campaign-id })
)

;; FundSteps: Get milestone details
(define-read-only (get-milestone (campaign-id uint) (milestone-id uint))
  (map-get? Milestones { campaign-id: campaign-id, milestone-id: milestone-id })
)

;; FundSteps: Get contribution details
(define-read-only (get-contribution (campaign-id uint) (contributor principal))
  (map-get? Contributions { campaign-id: campaign-id, contributor: contributor })
)

;; ========================================================================
;; Fund Release Functions
;; ========================================================================
;; FundSteps: Claim funds for a completed milestone
(define-public (claim-milestone (campaign-id uint) (milestone-id uint))
  (let
    (
      (campaign (unwrap! (map-get? Campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (milestone (unwrap! (map-get? Milestones { campaign-id: campaign-id, milestone-id: milestone-id }) ERR-INVALID-MILESTONE))
      (current-block block-height)
      (campaign-owner (get owner campaign))
      (milestone-amount (get amount milestone))
      (is-approved (get approved milestone))
      (is-completed (get completed milestone))
      (campaign-active (get active campaign))
    )
    ;; FundSteps: Authorization and state checks
    (asserts! (is-eq campaign-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! campaign-active ERR-CAMPAIGN-ENDED)
    (asserts! is-approved ERR-MILESTONE-NOT-APPROVED)
    (asserts! (not is-completed) ERR-MILESTONE-NOT-APPROVED)
    (asserts! (> milestone-amount u0) ERR-INVALID-MILESTONE)
    (asserts! (<= milestone-id u3) ERR-INVALID-MILESTONE)
    
    ;; FundSteps: Update milestone status
    (map-set Milestones
      { campaign-id: campaign-id, milestone-id: milestone-id }
      (merge milestone { completed: true })
    )
    
    ;; FundSteps: Check if this is the last milestone
    (if (and (is-eq milestone-id u3) (get completed (unwrap-panic (get-milestone campaign-id u1))) (get completed (unwrap-panic (get-milestone campaign-id u2))))
      (map-set Campaigns
        { campaign-id: campaign-id }
        (merge campaign { active: false })
      )
      false
    )
    
    ;; FundSteps: Log the claim event
    (print {
      event: "milestone-claimed",
      campaign-id: campaign-id,
      milestone-id: milestone-id,
      amount: milestone-amount,
      claimant: tx-sender,
      block-height: current-block
    })
    
    ;; FundSteps: Transfer funds
    (try! (as-contract (stx-transfer? milestone-amount tx-sender campaign-owner)))
    (ok true)
  )
)
