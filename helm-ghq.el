(require 'helm)

(defvar helm-c-source-ghq
  '((name . "ghq list")
    (init . (lambda ()
	      (helm-init-candidates-in-buffer 'global
		(shell-command-to-string "ghq list --full-path"))))
    (candidates-in-buffer)
    (action . find-file)))

;;;###autoload
(defun helm-ghq ()
  "Find file results of `ghq list'."
  (interactive)
  (helm '(helm-c-source-ghq) nil "Find file: " nil nil))

(provide 'helm-ghq)
