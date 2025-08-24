(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PROPOSAL (err u101))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u102))
(define-constant ERR-VOTING-ENDED (err u103))
(define-constant ERR-ALREADY-VOTED (err u104))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u105))
(define-constant ERR-PROPOSAL-NOT-ENDED (err u106))
(define-constant ERR-PROPOSAL-ALREADY-EXECUTED (err u107))

(define-constant MIN-REPUTATION-TO-PROPOSE u10)
(define-constant VOTING-PERIOD u144)
(define-constant QUORUM-THRESHOLD u50)

(define-data-var next-proposal-id uint u1)
(define-data-var contract-owner principal tx-sender)

(define-map members principal {
    reputation: uint,
    total-contributions: uint,
    join-block: uint
})

(define-map proposals uint {
    proposer: principal,
    title: (string-ascii 50),
    description: (string-ascii 200),
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    total-reputation-voted: uint,
    executed: bool
})

(define-map votes { proposal-id: uint, voter: principal } {
    vote: bool,
    reputation-weight: uint
})

(define-map reputation-actions principal uint)

(define-public (register-member)
    (let ((caller tx-sender))
        (if (is-none (map-get? members caller))
            (begin
                (map-set members caller {
                    reputation: u1,
                    total-contributions: u0,
                    join-block: stacks-block-height
                })
                (ok true))
            (ok false))))

(define-public (increase-reputation (member principal) (amount uint))
    (let ((current-member (unwrap! (map-get? members member) ERR-NOT-AUTHORIZED))
          (caller tx-sender))
        (asserts! (or (is-eq caller (var-get contract-owner)) (is-eq caller member)) ERR-NOT-AUTHORIZED)
        (map-set members member (merge current-member {
            reputation: (+ (get reputation current-member) amount),
            total-contributions: (+ (get total-contributions current-member) amount)
        }))
        (ok true)))

(define-public (create-proposal (title (string-ascii 50)) (description (string-ascii 200)))
    (let ((caller tx-sender)
          (member-data (unwrap! (map-get? members caller) ERR-NOT-AUTHORIZED))
          (proposal-id (var-get next-proposal-id)))
        (asserts! (>= (get reputation member-data) MIN-REPUTATION-TO-PROPOSE) ERR-INSUFFICIENT-REPUTATION)
        (map-set proposals proposal-id {
            proposer: caller,
            title: title,
            description: description,
            start-block: stacks-block-height,
            end-block: (+ stacks-block-height VOTING-PERIOD),
            yes-votes: u0,
            no-votes: u0,
            total-reputation-voted: u0,
            executed: false
        })
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)))

(define-public (vote (proposal-id uint) (vote-yes bool))
    (let ((caller tx-sender)
          (member-data (unwrap! (map-get? members caller) ERR-NOT-AUTHORIZED))
          (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
          (reputation-weight (get reputation member-data)))
        (asserts! (<= stacks-block-height (get end-block proposal)) ERR-VOTING-ENDED)
        (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: caller })) ERR-ALREADY-VOTED)
        (map-set votes { proposal-id: proposal-id, voter: caller } {
            vote: vote-yes,
            reputation-weight: reputation-weight
        })
        (if vote-yes
            (map-set proposals proposal-id (merge proposal {
                yes-votes: (+ (get yes-votes proposal) reputation-weight),
                total-reputation-voted: (+ (get total-reputation-voted proposal) reputation-weight)
            }))
            (map-set proposals proposal-id (merge proposal {
                no-votes: (+ (get no-votes proposal) reputation-weight),
                total-reputation-voted: (+ (get total-reputation-voted proposal) reputation-weight)
            })))
        (unwrap! (increase-reputation caller u1) ERR-NOT-AUTHORIZED)
        (ok true)))

(define-public (execute-proposal (proposal-id uint))
    (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND)))
        (asserts! (> stacks-block-height (get end-block proposal)) ERR-PROPOSAL-NOT-ENDED)
        (asserts! (not (get executed proposal)) ERR-PROPOSAL-ALREADY-EXECUTED)
        (asserts! (>= (get total-reputation-voted proposal) QUORUM-THRESHOLD) ERR-INSUFFICIENT-REPUTATION)
        (if (> (get yes-votes proposal) (get no-votes proposal))
            (begin
                (map-set proposals proposal-id (merge proposal { executed: true }))
                (unwrap! (increase-reputation (get proposer proposal) u5) ERR-NOT-AUTHORIZED)
                (ok true))
            (begin
                (map-set proposals proposal-id (merge proposal { executed: true }))
                (ok false)))))

(define-public (delegate-reputation (to-member principal) (amount uint))
    (let ((caller tx-sender)
          (caller-data (unwrap! (map-get? members caller) ERR-NOT-AUTHORIZED))
          (to-data (unwrap! (map-get? members to-member) ERR-NOT-AUTHORIZED)))
        (asserts! (>= (get reputation caller-data) amount) ERR-INSUFFICIENT-REPUTATION)
        (map-set members caller (merge caller-data {
            reputation: (- (get reputation caller-data) amount)
        }))
        (map-set members to-member (merge to-data {
            reputation: (+ (get reputation to-data) amount)
        }))
        (ok true)))

(define-read-only (get-member-data (member principal))
    (map-get? members member))

(define-read-only (get-member-reputation (member principal))
    (match (map-get? members member)
        member-data (get reputation member-data)
        u0))

(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id))

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes { proposal-id: proposal-id, voter: voter }))

(define-read-only (has-voted (proposal-id uint) (voter principal))
    (is-some (map-get? votes { proposal-id: proposal-id, voter: voter })))

(define-read-only (get-total-reputation)
    u0)

(define-read-only (is-proposal-active (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (<= stacks-block-height (get end-block proposal))
        false))

(define-read-only (calculate-voting-power (member principal))
    (let ((member-data (unwrap! (map-get? members member) u0))
          (base-reputation (get reputation member-data))
          (contribution-bonus (/ (get total-contributions member-data) u10))
          (longevity-bonus (/ (- stacks-block-height (get join-block member-data)) u1000)))
        (+ base-reputation contribution-bonus longevity-bonus)))


