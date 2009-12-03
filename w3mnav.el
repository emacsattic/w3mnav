;;; w3m-nav.el --- add additional Info-like navigation to w3m

;; Copyright (C) 2002-3 Neil W. Van Dyke

;; Author:   Neil W. Van Dyke <neil@neilvandyke.org>
;; Version:  0.5
;; X-URL:    http://www.neilvandyke.org/w3mnav/
;; X-CVS:    $Id: w3mnav.el,v 1.14 2003/07/05 23:24:40 neil Exp $ GMT

;; This is free software; you can redistribute it and/or modify it under the
;; terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 2, or (at your option) any later version.  This
;; is distributed in the hope that it will be useful, but without any warranty;
;; without even the implied warranty of merchantability or fitness for a
;; particular purpose.  See the GNU General Public License for more details.
;; You should have received a copy of the GNU General Public License along with
;; GNU Emacs; see the file `COPYING'.  If not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.

;;; Commentary:

;; `w3mnav' kludges some Info-like navigation keys into the `emacs-w3m' Web
;; browser (`http://emacs-w3m.namazu.org/').  This functionality was originally
;; part of Scheme support package Quack (`http://www.neilvandyke.org/quack/'),
;; and was intended to work with the numerous Scheme books that were converted
;; to HTML from LaTeX format.  It also works with some other HTML pages that
;; have book-like "next page" and "previous page" links.
;;
;; To install, put file `w3mnav.el' into one of your Emacs Lisp directories,
;; optionally byte-compile the file, and add a line like the following to your
;; `~/.emacs' file:
;;
;;     (require 'w3mnav)

;;; Change Log:

;; Version 0.5 (05-Jul-2003)  w3mnav's functionality might be incorporated into
;;     the official w3m, but for now w3mnav.el can be used separately.  This
;;     version has a few changes suggested by Katsumi Yamaoka.  Renamed
;;     functions to begin with `w3m-nav' instead of `w3mnav'.  Added `custom'
;;     settings, under the `w3m' group.  `w3mnav-different-browser' removed,
;;     since it appears redundant with the standard
;;     `w3m-view-url-with-external-browser'.
;;
;; Version 0.4 (07-Jan-2003) Removed accidental Quack dependency.
;; Version 0.3 (06-Jan-2002) Comment fixes.
;; Version 0.2 (04-Jan-2003) Fixes.
;; Version 0.1 (03-Jan-2003) Initial release, separated from Quack.

;;; Code:

(eval-and-compile (require 'w3m))

(defcustom w3m-nav-go-next-strings
  '("next" "next page" ">>" "next page >>>")
  "*List of strings for links that `w3m-nav-go-next' can follow."
  :type  '(repeat string)
  :group 'w3m)
  
(defcustom w3m-nav-go-prev-strings
  '("previous" "prev" "previous page" "<<" "<<< previous page")
  "*List of strings for links that `w3m-nav-go-prev' can follow."
  :type  '(repeat string)
  :group 'w3m)
  
(defcustom w3m-nav-go-top-strings
  '("contents" "first" "first page" "up" "up page" "home")
  "*List of strings for links that `w3m-nav-go-top' can follow."
  :type  '(repeat string)
  :group 'w3m)
  
(setq w3m-mode-map w3m-info-like-map)

(define-key w3m-mode-map "t" 'w3m-nav-go-top)
(define-key w3m-mode-map "[" 'w3m-nav-go-prev)
(define-key w3m-mode-map "]" 'w3m-nav-go-next)

(defun w3m-nav-without-side-whitespace (str)
  (save-match-data
    (if (string-match "^[ \t\n\r]+" str)
        (setq str (substring str (match-end 0))))
    (if (string-match "[ \t\n\r]+$" str)
        (setq str (substring str 0 (match-beginning 0))))
    str))

(defun w3m-nav-nav-links ()
  (let* ((result '())
         (search
          (function
           (lambda (start end)
             (let ((last nil))
               (goto-char start)
               (while (and (< (point) end)
                           (w3m-goto-next-anchor)
                           (or (not last)
                               (> (point) last)))
                 (setq last (point))
                 (let ((name-end (next-single-property-change
                                  (point)
                                  'w3m-anchor-sequence))
                       (url      (eval '(w3m-anchor))))
                   (when (and name-end url)
                     (let ((name (downcase (w3m-nav-without-side-whitespace
                                            (buffer-substring-no-properties
                                             (point)
                                             name-end)))))
                       (setq result (cons (cons name url) result)))))))))))
    (save-excursion
      (let* ((top-end (min (+ (point-min) 1000) (point-max))))
        (funcall search (point-min) top-end)
        (when (< top-end (point-max))
          (funcall search (max (- (point-min) 1000) top-end) (point-max)))))
    (reverse result)))

(defun w3m-nav-go (names page-kind)
  (let ((links (w3m-nav-nav-links))
        (url   nil))
    (when links
      (while (and names (not url))
        (setq url (cdr (assoc (car names) links)))
        (setq names (cdr names))))
    (if url
        (w3m-goto-url url)
      (error "Sorry, no %s page link could be found." page-kind))))

(defun w3m-nav-go-next ()
  (interactive)
  (w3m-nav-go w3m-nav-go-next-strings "next"))

(defun w3m-nav-go-prev ()
  (interactive)
  (w3m-nav-go w3m-nav-go-prev-strings "previous"))

(defun w3m-nav-go-top ()
  ;; TODO: We should make separate `t' and `u' commands now.  The `u' command
  ;;       should fallback to `w3m-view-parent-page', which is the normal
  ;;       binding for `u'.  Or perhaps `u' should fallback to "top" and then
  ;;       to the normal binding.
  (interactive)
  (w3m-nav-go w3m-nav-go-top-strings "top"))

(provide 'w3mnav)

;; w3mnav.el ends here
