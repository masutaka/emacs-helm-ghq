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

(defun helm-ghq--init ()
  (with-current-buffer (helm-candidate-buffer 'global)
    (unless (zerop (call-process "ghq" nil t nil "list" "--full-path"))
      (error "Failed: 'ghq list --full-path'"))))

(defvar helm-ghq-source
  '((name . "ghq list")
    (init . helm-ghq--init)
    (candidates-in-buffer)
    (action . find-file)))

;;;###autoload
(defun helm-ghq ()
  "Find file results of `ghq list'."
  (interactive)
  (helm :sources '(helm-ghq-source) :prompt "Find file: "
        :buffer "*helm-ghq*"))

(provide 'helm-ghq)
