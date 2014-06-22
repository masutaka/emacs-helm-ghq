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
