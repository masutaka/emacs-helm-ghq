;;; helm-ghq.el --- ghq with helm interface -*- lexical-binding: t; -*-

;; Copyright (C) 2015 by Takashi Masuda

;; Author: Takashi Masuda <masutaka.net@gmail.com>
;; URL: https://github.com/masutaka/emacs-helm-ghq
;; Version: 1.4.5
;; Package-Requires: ((helm "1.7.6"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; helm-ghq.el provides a helm interface to "ghq".

;;; Code:

(require 'helm)
(require 'helm-mode)
(require 'helm-files)

(defgroup helm-ghq nil
  "ghq with helm interface"
  :prefix "helm-ghq-"
  :group 'helm)

(defcustom helm-ghq-command-ghq
  "ghq"
  "*A ghq command"
  :type 'string
  :group 'helm-ghq)

(defcustom helm-ghq-command-ghq-arg-root
  '("root")
  "*Arguments for getting ghq root path using ghq command"
  :type '(repeqt string)
  :group 'helm-ghq)

(defcustom helm-ghq-command-git
  "git"
  "*A git command"
  :type 'string
  :group 'helm-ghq)

(defcustom helm-ghq-command-git-arg-root
  '("config" "ghq.root")
  "*Arguments for getting ghq root path using git command"
  :type '(repeqt string)
  :group 'helm-ghq)

(defcustom helm-ghq-command-hg
  "hg"
  "*A hg command"
  :type 'string
  :group 'helm-ghq)

(defun helm-ghq--open-dired (file)
  (dired (file-name-directory file)))

(defvar helm-ghq--action
  '(("Open File" . find-file)
    ("Open File other window" . find-file-other-window)
    ("Open File other frame" . find-file-other-frame)
    ("Open Directory" . helm-ghq--open-dired)))

(defvar helm-source-ghq
  (helm-build-sync-source "ghq"
    :candidates #'helm-ghq--list-candidates
    :match #'helm-ghq--files-match-only-basename
    :filter-one-by-one (lambda (candidate)
                         (if helm-ff-transformer-show-only-basename
                             candidate
                           (cons (cdr candidate) (cdr candidate))))
    :keymap helm-generic-files-map
    :help-message helm-generic-file-help-message
    :action helm-ghq--action)
  "Helm source for ghq.")

(defun helm-ghq--files-match-only-basename (candidate)
  "Allow matching only basename of file when \" -b\" is added at end of pattern.
If pattern contain one or more spaces, fallback to match-plugin
even is \" -b\" is specified."
  (let ((source (helm-get-current-source)))
    (if (string-match "\\([^ ]*\\) -b\\'" helm-pattern)
        (progn
          (helm-attrset 'no-matchplugin nil source)
          (string-match (match-string 1 helm-pattern)
                        (helm-basename candidate)))
      ;; Disable no-matchplugin by side effect.
      (helm-aif (assq 'no-matchplugin source)
          (setq source (delete it source)))
      (string-match
       (replace-regexp-in-string " -b\\'" "" helm-pattern)
       candidate))))

(defmacro helm-ghq--line-string ()
  `(buffer-substring-no-properties
    (line-beginning-position) (line-end-position)))

(defun helm-ghq--root-fallback ()
  (erase-buffer)
  (unless (zerop (apply #'process-file
			helm-ghq-command-git nil t nil helm-ghq-command-git-arg-root))
    (error "Failed: Can't find ghq.root"))
  (goto-char (point-min))
  (expand-file-name (helm-ghq--line-string)))

(defun helm-ghq--root ()
  (with-temp-buffer
    (apply #'process-file
	   helm-ghq-command-ghq nil t nil helm-ghq-command-ghq-arg-root)
    (goto-char (point-min))
    (let ((output (helm-ghq--line-string)))
      (if (string-match-p "\\`No help topic" output)
          (helm-ghq--root-fallback)
        (expand-file-name output)))))

(defun helm-ghq--list-candidates ()
  (with-temp-buffer
    (unless (zerop (call-process helm-ghq-command-ghq nil t nil "list" "--full-path"))
      (error "Failed: ghq list --full-path"))
    (let ((ghq-root (helm-ghq--root))
          paths)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((path (helm-ghq--line-string)))
          (push (cons (file-relative-name path ghq-root) path) paths))
        (forward-line 1))
      (reverse paths))))

(defun helm-ghq--list-ls-files ()
  (with-current-buffer (helm-candidate-buffer 'global)
    (unless (or (zerop (call-process helm-ghq-command-git nil '(t nil) nil "ls-files"))
		(zerop (call-process helm-ghq-command-hg nil t nil "manifest")))
      (error "Failed: git ls-files | hg manifest"))))

(defun helm-ghq--source (repo)
  (let ((name (file-name-nondirectory (directory-file-name repo))))
    (helm-build-in-buffer-source name
      :init #'helm-ghq--list-ls-files
      :action helm-ghq--action)))

(defun helm-ghq--repo-to-user-project (repo)
  (cond ((string-match "github.com/\\(.+\\)" repo)
         (match-string-no-properties 1 repo))
        ((string-match "code.google.com/\\(.+\\)" repo)
         (match-string-no-properties 1 repo))))

(defun helm-ghq--update-repository (repo)
  (let ((user-project (helm-ghq--repo-to-user-project repo)))
    (async-shell-command (concat helm-ghq-command-ghq " get -u " user-project))))

(defun helm-ghq--source-update (repo)
  (helm-build-sync-source "Update Repository"
    :candidates '(" ") ; dummy
    :action (lambda (_c)
              (helm-ghq--update-repository repo))))

;;;###autoload
(defun helm-ghq ()
  (interactive)
  (let ((repo (helm-comp-read "ghq-list: "
                              (helm-ghq--list-candidates)
                              :name "ghq list"
                              :must-match t)))
    (let ((default-directory (file-name-as-directory repo)))
      (helm :sources (list (helm-ghq--source default-directory)
                           (helm-ghq--source-update repo))
            :buffer "*helm-ghq-list*"))))

(provide 'helm-ghq)

;;; helm-ghq.el ends here
