;;; helm-ghq.el --- ghq with helm interface

;; Copyright (C) 2014 by Takashi Masuda

;; Author: Takashi Masuda <masutaka.net@gmail.com>
;; URL: https://github.com/masutaka/emacs-helm-ghq
;; Version: 1.0.0
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

(defun helm-ghq--open-dired (file)
  (dired (file-name-directory file)))

(defmacro helm-ghq--line-string ()
  `(buffer-substring-no-properties
    (line-beginning-position) (line-end-position)))

(defun helm-ghq--root ()
  (with-temp-buffer
    (unless (zerop (call-process "git" nil t nil "config" "ghq.root"))
      (error "Failed: Can't find ghq.root"))
    (goto-char (point-min))
    (expand-file-name (helm-ghq--line-string))))

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
    (unless (zerop (call-process "git" nil t nil "ls-files"))
      (error "Failed: 'git ls-files'"))))

(defun helm-ghq--source (repo)
  (let ((name (file-name-nondirectory (directory-file-name repo))))
    `((name . ,name)
      (init . helm-ghq--list-ls-files)
      (candidates-in-buffer)
      (action . (("Open File" . find-file)
                 ("Open File other window" . find-file-other-window)
                 ("Open File other frame" . find-file-other-frame)
                 ("Open Directory" . helm-ghq--open-dired))))))

;;;###autoload
(defun helm-ghq ()
  (interactive)
  (let ((repo (helm-comp-read "ghq-list: "
                              (helm-ghq--list-candidates)
                              :name "ghq list"
                              :must-match t)))
    (let ((default-directory (file-name-as-directory repo)))
      (helm :sources (helm-ghq--source default-directory)
            :buffer "*helm-ghq-list*"))))

(provide 'helm-ghq)
