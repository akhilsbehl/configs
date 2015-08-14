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
		smooth-scrolling
        autopair
		))
;; This will also load the theme if standalone. For loading the theme when running as a client, see the appearance section.
(el-get-bundle gruvbox-theme in greduan/emacs-theme-gruvbox)
(require-package 'main-line)

;;;; Evil and related packages

;;; Do not let some of the modes over-ride evil
(custom-set-variables
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

;;; No tool bar, scroll, or menubar
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;;; Vim like smooth scrolling
(setq scroll-margin 5
      scroll-conservatively 9999
      scroll-step 1)

;;; Main-line mode bar
(require 'main-line)
(setq main-line-separator-style 'wave)

;;; Gruvbox and Monaco font.
;; http://stackoverflow.com/questions/18904529/after-emacs-deamon-i-can-not-see-new-theme-in-emacsclient-frame-it-works-fr
(if (daemonp)
  (add-hook 'after-make-frame-functions
            (lambda (frame)
              (select-frame frame)
              (set-face-attribute 'default nil :font "Monaco 11")
              (load-theme 'gruvbox t))))

(global-linum-mode 1)
(setq-default tab-width 4 indent-tabs-mode nil)

(setq evil-normal-state-cursor '("orange" box))
(setq evil-visual-state-cursor '("grey" box))
(setq evil-operator-state-cursor '("orange" hollow))
(setq evil-insert-state-cursor '("orange" bar))
(setq evil-emacs-state-cursor '("red" box))
(setq evil-replace-state-cursor '("red" underline))

(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)

(add-hook 'prog-mode-hook 'hs-minor-mode)

;;; Make escape quit in the minibuffer too
(defun minibuffer-keyboard-quit ()
  "Abort recursive edit. In Delete Selection mode, if the mark is
   active, just deactivate it; then it takes a second \\[keyboard-quit]
   to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))

(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)
(global-set-key [escape] 'evil-exit-emacs-state)

;;;; Use vim-like tabs
(load "elscreen" "ElScreen" t)
(elscreen-start)
(define-key evil-normal-state-map "gc" 'elscreen-create)
(define-key evil-normal-state-map "gd" 'elscreen-kill)
(define-key evil-normal-state-map "gj" 'elscreen-previous)
(define-key evil-normal-state-map "gk" 'elscreen-next)
    
;;;; Version control settings
(setq vc-follow-symlinks t)

;;;; The backups and auto-saves
(setq backup-directory-alist
      `((".*" . "~/.emacs-auto-backups")))
(setq auto-save-file-name-transforms
      `((".*" "~/.emacs-auto-saves" t)))

(setq kept-old-versions   1  ; Keep one old copy.
      kept-new-versions   1  ; Keep one new copy.
      auto-save-default   t  ; Save every buffer that visits a file.
      auto-save-timeout  25  ; Number of idle seconds to save at.
      auto-save-interval 50  ; Number of keystrokes to save at.
      )

;;; Miscellaneous

;; Paren matching and autoclosing.
(show-paren-mode t)
(require 'autopair)
(add-hook 'prog-mode-hook 'autopair-mode)

;;;; TODO: Packages & Functionality to explore
; 1. Yasnippet
; 2. Helm
; 3. Org-mode
; 4. Auto-completion?
; 5. Linting especially Flake8
; 6. Markdown and latex with previews (maybe through org-mode itself)
; 7. Email
; 8. Documentation seek for arbit languages
; 9. Multiple-cursors
; 10. Autocompletion
; 11. Alignment
; 12. Buffer management shortcuts
; 13. Read undo-tree
; 14. IPython interaction
; 15. ESS
; 16. Mark file executable if starts with a shebang
; 17. Comment boxes
; 18. Map ex commands to keybindings
; 19. Sudo on the fly
; 20. Copy to system clipboard
; 21. Magit
