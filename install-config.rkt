#lang racket

(define home (find-system-path 'home-dir))

;; utils
(define (config-file? file-name)
  (define/contract (has-extension? file-name ext)
    ((or/c path-string? path-for-some-system?) bytes? . -> . boolean?)
    (equal? (filename-extension file-name) ext))
  (and
   (not (has-extension? file-name #"rkt"))
   (not (has-extension? file-name #"org"))
   (not (string-contains? (path->string file-name) "#"))
   (not (string-contains? (path->string file-name) "~"))
   ))

;; Returns a list of copy actions from kde-config to config-dest
;;   copy action: (or/c (cons 'mkdir . destination) (cons src . destination))
(define (copy-actions kde-config config-dest)
  (for/list ([f (in-directory kde-config)] #:when (config-file? f))
            (let-values ([(base name must-be-dir?) (split-path f)])
              (let ([dest (build-path config-dest name)])
                (cond
                  [(directory-exists? f) (cons 'mkdir dest)]
                  [#t (cons f dest)])))))

(define (print-copy-action action)
  (match action
    [(cons 'mkdir dest) (printf "mkdir ~a~n" (path->string dest))]
    [(cons src dest) (printf "~a -> ~a~n" (path->string src) (path->string dest))]))

(define (copy action)
  (match action
    [(cons 'mkdir dest) (unless (directory-exists? dest) (make-directory dest))]
    [(cons src dest) (copy-file src dest #t)]))

;; parameters
(define kde-config (make-parameter (build-path home "dev/kde-config")))
(define config-dest (make-parameter (build-path home ".config")))
(define execute? (make-parameter #f))

(command-line
 #:once-each
 [("-x" "--execute") "Actually do something."
                     (execute? #t)])
(unless (execute?)
  (displayln "# Dry run. Not doing anything."))
(for ([a (copy-actions (kde-config) (config-dest))])
     (print-copy-action a)
     (when (execute?)
       (copy a)))

