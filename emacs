;;;; The standard package manager
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("org" . "http://orgmode.org/elpa/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")
                         ("melpa-stable" . "http://melpa-stable.milkbox.net/packages/")))
(package-initialize)

(defun require-package (package)
  (unless (package-installed-p package)
    (unless (assoc package package-archive-contents)
      (package-refresh-contents))
    (package-install package)))

;;;; El-get for additional packages

(add-to-list 'load-path "~/.emacs.d/el-get/el-get")

;;; Install el-get if not available
(unless (require 'el-get nil 'noerror)
  (with-current-buffer
      (url-retrieve-synchronously
       "https://raw.githubusercontent.com/dimitri/el-get/master/el-get-install.el")
    (goto-char (point-max))
    (eval-print-last-sexp)))

(add-to-list 'el-get-recipe-path "~/.emacs.d/el-get-user/recipes")

;;; Sync all packages at startup
(el-get 'sync '(
                evil
                evil-surround
                evil-numbers
                evil-leader
                evil-nerd-commenter
                evil-exchange
                ))
(el-get-bundle gruvbox-theme in greduan/emacs-theme-gruvbox)  ; Loads theme too
(require-package 'main-line)

;;;; Evil and related packages
;;; Config based on the Evil wiki
;; Do not let some of the modes over-ride evil
(custom-set-variables
 '(evil-overriding-maps nil)
 '(evil-intercept-maps nil))

;; Let everything open up in Evil motion (normal?) mode.
(setq evil-motion-state-modes (append evil-emacs-state-modes
				      evil-motion-state-modes))
(setq evil-emacs-state-modes nil)

(defun my-move-key (keymap-from keymap-to key)
     "Moves key binding from one keymap to another, deleting from the
      old location."
     (define-key keymap-to key (lookup-key keymap-from key))
     (define-key keymap-from key nil))
(my-move-key evil-motion-state-map evil-normal-state-map (kbd "RET"))
(my-move-key evil-motion-state-map evil-normal-state-map " ")

;;; Surround
(require 'evil-surround)
(global-evil-surround-mode 1)

;;; Incrementing and decrementing
(require 'evil-numbers)
(define-key evil-normal-state-map (kbd "+") 'evil-numbers/inc-at-pt)
(define-key evil-normal-state-map (kbd "-") 'evil-numbers/dec-at-pt)

;;; Get me a leader key
(require 'evil-leader)
(global-evil-leader-mode)
(evil-leader/set-leader ",")

;;; Nerd commenter. Make sure to use after evil-leader
(require 'evil-nerd-commenter)
(evil-leader/set-key
  "ct" 'evilnc-comment-or-uncomment-lines
  "ci" 'evilnc-toggle-invert-comment-line-by-line
  ",c" 'evilnc-comment-operator)
;; TODO: Find a way to remove redundant mappings and change the operator mapping for this plugin.

(require 'evil-exchange)
(evil-exchange-install)

;;; Do this last
(require 'evil)
(evil-mode 1)

;;;; Appearance settings

;;; No splash
(setq inhibit-startup-message t)

;;; Monaco 12 pt.
(set-face-attribute
  'default nil
  :font "Monaco 11")

;;; Main-line mode bar
(require 'main-line)
(setq main-line-separator-style 'curve)
