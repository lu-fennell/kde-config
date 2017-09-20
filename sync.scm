(use-modules (ice-9 match))

;; Configuration
(define files-to-sync
  '("khotkeysrc"
    "kglobalshortcutsrc"
    "kdeglobals"
    "dolphinrc"))

;; The directory of the repository. 
(define repo-dir (make-parameter (getcwd)))

;; The directory of the systems config directory
(define config-dir (make-parameter (string-append (getenv "HOME") "/.config")))


;; Utilities
(define (exit-status-ok? n) (equal? n 0))


;; Implementation

;; :: (listof (list path? path?))
(define comparisons
  (map
   (lambda (fname)
     (list (string-append (repo-dir) "/" fname)
           (string-append (config-dir) "/" fname)))
   files-to-sync
   ))

(define (different-files)
  (define (call-diff left-file right-file)
    (with-output-to-file "/dev/null"
      (lambda () (system* "diff" "--brief" left-file right-file))))
  (filter
   (match-lambda
    ((repo-file config-file) (not (exit-status-ok?
                              (call-diff repo-file config-file)))))
   comparisons))

(define (sync-config-files)
  )
