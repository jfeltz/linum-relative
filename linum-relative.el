;;; linum-relative.el --- display relative line number in emacs.

;; Copyright (c) 2013 Yen-Chin, Lee.
;;
;; Author: coldnew <coldnew.tw@gmail.com>
;; Keywords: converience
;; X-URL: http://github.com/coldnew/linum-relative
;; Version: 0.4

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; ![Screenshot](https://github.com/coldnew/linum-relative/raw/master/screenshot/screenshot1.jpg)
;;
;; linum-relative lets you display relative line numbers for current buffer.
;;

;;; Installation:

;; If you have `melpa` and `emacs24` installed, simply type:
;;
;;      M-x package-install linum-relative
;;
;; In your .emacs
;;
;;      (require 'linum-relative)

;;; Code:

(eval-when-compile (require 'cl))
(require 'linum)

(defgroup linum-relative nil
  "Show relative line numbers on fringe."
  :group 'convenience)

;;;; Faces
(defface linum-relative-current-face
  '((t :inherit linum :foreground "#CAE682" :background "#444444" :weight bold))
  "Face for displaying current line."
  :group 'linum-relative)

;;;; Customize Variables

(defcustom linum-relative-layout 'left
  "Layout to use for linum-relative. Currently we has following layout:

left   - Show linum-relative on left, this option will overrite linum-mode. (default)
right  - Show linum-relative on right. NOTE: This option currently work the same as left-right.
left-right - Show linum-relative on both left and show linum on right fringe.
"
  :type 'symbol
  :group 'linum-relative)

(defcustom linum-relative-current-symbol "0"
  "The symbol you want to show on the current line, by default it is 0.
   You can use any string like \"->\". If this variable is empty string,
linum-releative will show the real line number at current line."
  :type 'string
  :group 'linum-relative)

(defcustom linum-relative-plusp-offset 0
  "Offset to use for positive relative line numbers."
  :type 'integer
  :group 'linum-relative)

(defcustom linum-relative-format "%3s"
  "Format for each line. Good for adding spaces/paddings like so: \" %3s \""
  :type 'string
  :group 'linum-relative)

;;;; Internal Variables

(defvar linum-relative-last-pos 0
  "Store last position.")

;;;; Advices
(defadvice linum-update (before relative-linum-update activate)
  "Update last position of linum-relative. If use `right'
or `left-right' layout, create right fringe."
  (let* ((window (get-buffer-window))
         (width (car (window-margins window))))
    ;; If user use linum-relative right or left-right layout,
    ;; set the margin on right fringe and make it has same width as left
    ;; margin.
    (if (or (eq 'right linum-relative-layout)
            (eq 'left-right linum-relative-layout))
        (progn
          (linum-relative-update-right-fringe (line-number-at-pos))
          (set-window-margins window width width))
      (set-window-margins window 0 0))
    ;; Update last position of linum-relative
    (setq linum-relative-last-pos (line-number-at-pos))))

(defadvice linum-delete-overlays (after linum-relative-right-delete activate)
  "Remove right fringe when deactive linum-mode."
  (when (or (eq 'right linum-relative-layout)
            (eq 'left-right linum-relative-layout))
    (set-window-margins (get-buffer-window) 0 0)))

;;;; Functions
(defun linum-relative (line-number)
  "Show relative line-number on left fringe."
  (let* ((diff1 (abs (- line-number linum-relative-last-pos)))
         (diff (if (minusp diff1)
                   diff1
                 (+ diff1 linum-relative-plusp-offset)))
         (current-p (= diff linum-relative-plusp-offset))
         (current-symbol (if (and linum-relative-current-symbol current-p)
                             (if (string= "" linum-relative-current-symbol)
                                 (number-to-string line-number)
                               linum-relative-current-symbol)
                           (number-to-string diff)))
         (face (if current-p 'linum-relative-current-face 'linum)))
    (propertize (format linum-relative-format current-symbol) 'face face)))

(defun linum-relative-update-right-fringe (line-number)
  "Update relative numbers on the right margin."
  (dolist (ov (overlays-in (window-start) (window-end)))
    (let* ((show-relative-p (if (eq linum-format 'relative) nil t))
	   (str (overlay-get ov 'linum-str))
	   (face 'linum-relative-current-face)
	   (nstr (if str
		     (number-to-string
		      (abs (- (string-to-number str) line-number)))))
	   (nstr2 (if nstr
		      (if (eq 'linum-relative linum-format)
			  (number-to-string
			   (+ line-number (string-to-number nstr)))
			nstr))))
      (when nstr2
	;; copy string properties
	(set-text-properties 0 (length nstr2) (text-properties-at 0 str) nstr2)
	(overlay-put ov 'after-string
		     (propertize " " 'display `((margin right-margin) ,nstr2)))
;;	(overlay-put ov 'face face)
	))))

(defun linum-relative-toggle ()
  "Toggle between linum-relative and linum."
  (interactive)
  (if (eq linum-format 'dynamic)
      (setq linum-format 'linum-relative)
    (setq linum-format 'dynamic)))

(setq linum-format 'linum-relative)

(provide 'linum-relative)
;;; linum-relative.el ends here.

;;(setq linum-relative-layout 'left)
(setq linum-relative-layout 'right)
