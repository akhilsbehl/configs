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
		elscreen
		))
;; This will also load the theme if standalone. For loading the theme when running as a client, see the appearance section.
(el-get-bundle gruvbox-theme in greduan/emacs-theme-gruvbox)
(require-package 'main-line)

;;;; Evil and related packages

;;; Do not let some of the modes over-ride evil
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("ca8350a6affc43fc36f84a5271e6d5278857185753cd91a899d1f88be062f77b" default)))
 '(evil-intercept-maps nil)
 '(evil-overriding-maps nil))

;;; Let everything open up in Evil motion (normal?) mode.
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

(require 'evil-exchange)
(evil-exchange-install)

;;; Do this last
(require 'evil)
(evil-mode 1)

;;;; Appearance settings

;;; No splash
(setq inhibit-startup-message t)

;;; Main-line mode bar
(require 'main-line)
(setq main-line-separator-style 'curve)

;;; Gruvbox and Monaco font.
;; http://stackoverflow.com/questions/18904529/after-emacs-deamon-i-can-not-see-new-theme-in-emacsclient-frame-it-works-fr
(if (daemonp)
  (add-hook 'after-make-frame-functions
            (lambda (frame)
              (select-frame frame)
              (set-face-attribute 'default nil :font "Monaco 11")
              (load-theme 'gruvbox t))))

(setq evil-normal-state-cursor '("orange" box))
(setq evil-visual-state-cursor '("grey" box))
(setq evil-operator-state-cursor '("orange" hollow))
(setq evil-insert-state-cursor '("orange" bar))
(setq evil-emacs-state-cursor '("red" box))
(setq evil-replace-state-cursor '("red" underline))

;;;; Use vim-like tabs
(load "elscreen" "ElScreen" t)
(elscreen-start)
(define-key evil-normal-state-map "gt" 'elscreen-create)
(define-key evil-normal-state-map "gw" 'elscreen-kill)
(define-key evil-normal-state-map "gj" 'elscreen-previous)
(define-key evil-normal-state-map "gk" 'elscreen-next)
    

;;;; The backups and auto-saves
(setq backup-directory-alist
      `((".*" . "~/.emacs-auto-backups")))
(setq auto-save-file-name-transforms
      `((".*" . "~/.emacs-auto-saves" t)))

(setq kept-old-versions   1  ; Keep one old copy.
      kept-new-versions   1  ; Keep one new copy.
      auto-save-default   t  ; Save every buffer that visits a file.
      auto-save-timeout  25  ; Number of idle seconds to save at.
      auto-save-interval 50  ; Number of keystrokes to save at.
      )

;;;; Version control settings
(setq vc-follow-symlinks t)
