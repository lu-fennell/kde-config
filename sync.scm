(use-modules (ice-9 match)
             (ice-9 popen)
	     (ice-9 getopt-long))

;; options
(define options
  (getopt-long (command-line) 
               '((sync-to-repo (value #f))
                 (sync-to-config (value #f)))))

;; Configuration
(define files-to-sync
  '(
    "dolphinrc"
    "kdeglobals"
    "kglobalshortcutsrc"
    "khotkeysrc"
    "klipperrc"
    "konsolerc"
    "kwinrc"
    "kwinrulesrc"
    "mimeapps.list"
    "plasmarc"
    "touchpadrc"
    ))

;; The directory of the repository. 
(define repo-dir (make-parameter (getcwd)))

;; The directory of the systems config directory
(define config-dir (make-parameter (string-append (getenv "HOME") "/.config")))


;; Utilities
(define (exit-status-ok? n) (equal? n 0))

(define (repo-currently-clean?)
  (define p (open-input-pipe "git status --porcelain"))
  (define some-output (read p))
  (close-pipe p)
  (eof-object? some-output)
  )

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
      (lambda ()
        (close-pipe
         (open-pipe* OPEN_READ "diff" "--brief" left-file right-file)))))
  (filter
   (match-lambda
    ((repo-file config-file) (not (exit-status-ok?
                              (call-diff repo-file config-file)))))
   comparisons))

(define (sync-config->repo)
  (when (not (repo-currently-clean?))
        (error "Repo is not clean. Aborting."))
  (for-each
   (match-lambda
    ((repo-file config-file)
     (system* "cp" "-v" config-file repo-file)))
   (different-files)))

(when (and (option-ref options 'sync-to-repo #f)
     (option-ref options 'sync-to-config #f)
     )
    (error "Only one command allowed, --sync-to-repo OR --sync-to-config"))

(when (option-ref options 'sync-to-repo #f)
  (sync-config->repo))

(when (option-ref options 'sync-to-config #f)
  (error "sync-to-config not implemented yet"))
