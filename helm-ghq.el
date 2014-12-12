;;; helm-ghq.el --- ghq with helm interface

;; Copyright (C) 2014 by Takashi Masuda

;; Author: Takashi Masuda <masutaka.net@gmail.com>
;; URL: https://github.com/masutaka/emacs-helm-ghq
;; Version: 1.4.0
;; Package-Requires: ((helm "1.6.2"))

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

;;; Code:

(require 'helm)
(require 'helm-mode)
(require 'helm-files)

(defun helm-ghq--open-dired (file)
  (dired (file-name-directory file)))

(defvar helm-source-ghq
  `((name . "ghq")
    (candidates . helm-ghq--list-candidates)
    (filtered-candidate-transformer
     . (lambda (candidates _source)
         (cl-loop for i in candidates
                  if helm-ff-transformer-show-only-basename
                  collect (cons (helm-basename i) i)
                  else collect i)))
    (keymap . ,helm-generic-files-map)
    (help-message . helm-generic-file-help-message)
    (mode-line . helm-generic-file-mode-line-string)
    (action . ,(cdr (helm-get-actions-from-type
                     helm-source-locate))))
  "Helm source for ghq.")

(defmacro helm-ghq--line-string ()
  `(buffer-substring-no-properties
    (line-beginning-position) (line-end-position)))

(defun helm-ghq--root-fallback ()
  (erase-buffer)
  (unless (zerop (process-file "git" nil t nil "config" "ghq.root"))
    (error "Failed: Can't find ghq.root"))
  (goto-char (point-min))
  (expand-file-name (helm-ghq--line-string)))

(defun helm-ghq--root ()
  (with-temp-buffer
    (process-file "ghq" nil t nil "root")
    (goto-char (point-min))
    (let ((output (helm-ghq--line-string)))
      (if (string-match-p "\\`No help topic" output)
          (helm-ghq--root-fallback)
        (expand-file-name output)))))

(defun helm-ghq--list-candidates ()
  (with-temp-buffer
    (unless (zerop (call-process "ghq" nil t nil "list" "--full-path"))
      (error "Failed: ghq list --full-path'"))
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
    (unless (or (zerop (call-process "git" nil '(t nil) nil "ls-files"))
		(zerop (call-process "hg" nil t nil "manifest")))
      (error "Failed: 'git ls-files | hg manifest'"))))

(defun helm-ghq--source (repo)
  (let ((name (file-name-nondirectory (directory-file-name repo))))
    `((name . ,name)
      (init . helm-ghq--list-ls-files)
      (candidates-in-buffer)
      (action . (("Open File" . find-file)
                 ("Open File other window" . find-file-other-window)
                 ("Open File other frame" . find-file-other-frame)
                 ("Open Directory" . helm-ghq--open-dired))))))

(defun helm-ghq--repo-to-user-project (repo)
  (cond ((string-match "github.com/\\(.+\\)" repo)
         (match-string-no-properties 1 repo))
        ((string-match "code.google.com/\\(.+\\)" repo)
         (match-string-no-properties 1 repo))))

(defun helm-ghq--update-repository (repo)
  (let ((user-project (helm-ghq--repo-to-user-project repo)))
    (async-shell-command (concat "ghq get -u " user-project))))

(defun helm-ghq--source-update (repo)
  `((name . "Update Repository")
    (candidates . (" ")) ;; dummy
    (action . (lambda (_c)
                (helm-ghq--update-repository ,repo)))))

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
