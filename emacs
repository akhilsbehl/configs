;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; El-get as the default package manager

(add-to-list 'load-path "~/.emacs.d/el-get/el-get")

;;; Install el-get if not available
(unless (require 'el-get nil 'noerror)
  (with-current-buffer
      (url-retrieve-synchronously
       (concat "https://raw.githubusercontent.com/"
               "dimitri/el-get/master/el-get-install.el"))
    (goto-char (point-max))
    (eval-print-last-sexp)))

(add-to-list 'el-get-recipe-path "~/.emacs.d/el-get-user/recipes")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; The standard package manager for other stuff

(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("org" . "http://orgmode.org/elpa/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")
                         ("melpa-stable" .
                          "http://melpa-stable.milkbox.net/packages/")))
(package-initialize)

(defun require-package (pkg)
  (unless (package-installed-p pkg)
    (unless (assoc pkg package-archive-contents)
      (package-refresh-contents))
    (package-install pkg)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Sync all packages at startup

;;; Use this section for standard edition el-get packages
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
                company-mode
                yasnippet
                fill-column-indicator
                flycheck
                ))

;;; Use this section for el-get packages that need to be bundled.

;; This will also load the theme if standalone. For loading the theme when
;; running as a client, see the appearance section.
(el-get-bundle gruvbox-theme in greduan/emacs-theme-gruvbox)

;;; Use this section for packages that need to be installed using `package`
(require-package 'main-line)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Evil and related packages

;;; Do not let some of the modes over-ride evil
(custom-set-variables
 '(evil-intercept-maps nil)
 '(evil-overriding-maps nil))

;;; Let everything open up in Evil motion (normal?) mode.
(setq evil-motion-state-modes (append evil-emacs-state-modes
                                      evil-motion-state-modes))
(setq evil-emacs-state-modes nil)

;;; http://www.emacswiki.org/emacs/Evil
(defun transfer-key (from-keymap to-keymap key)
  "Moves key binding from one keymap to another, deleting from the
      old location."
  (define-key to-keymap key (lookup-key from-keymap key))
  (define-key from-keymap key nil))
(transfer-key evil-motion-state-map evil-normal-state-map (kbd "RET"))
(transfer-key evil-motion-state-map evil-normal-state-map " ")

;;; Surround
(global-evil-surround-mode 1)

;;; Incrementing and decrementing
(define-key evil-normal-state-map (kbd "+") 'evil-numbers/inc-at-pt)
(define-key evil-normal-state-map (kbd "-") 'evil-numbers/dec-at-pt)

;;; Get me a leader key
(global-evil-leader-mode)
;; This should always be a comma because a) that is what I have always used, and
;; b) I've hard-coded commas in other commands on that assumption.
(evil-leader/set-leader ",")

;;; Nerd commenter. Make sure to use after evil-leader
(evil-leader/set-key
  "ct" 'evilnc-comment-or-uncomment-lines
  "ci" 'evilnc-toggle-invert-comment-line-by-line
  ",c" 'evilnc-comment-operator)

;;; Swap selections / text-objects
(evil-exchange-install)

;;; Some niceties to work with undo-tree
(evil-leader/set-key
  "uv" 'undo-tree-visualize
  "ud" 'undo-tree-visualizer-toggle-diff
  "ua" 'undo-tree-visualizer-abort
  "uq" 'undo-tree-visualizer-quit)

;;; Do this last
(evil-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Appearance settings

;;; No splash
(setq inhibit-startup-message t)

;;; Keep scratch empty
(setq initial-scratch-message nil)

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

;;; Show line numbers
(global-linum-mode 1)

;;; Use 4 spaces for tabs
(setq-default tab-width 4 indent-tabs-mode nil)

;;; Colors for the various edit modes
(setq evil-normal-state-cursor '("orange" box))
(setq evil-visual-state-cursor '("grey" box))
(setq evil-operator-state-cursor '("orange" hollow))
(setq evil-insert-state-cursor '("orange" bar))
(setq evil-emacs-state-cursor '("red" box))
(setq evil-replace-state-cursor '("red" underline))

;;; Visually specify the right limit for programming and auto-break
(add-hook 'prog-mode-hook
          (lambda ()
            (turn-on-auto-fill)
            (fci-mode)
            (set-fill-column 80)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Use vim-like tabs
(load "elscreen" "ElScreen" t)
(elscreen-start)
(define-key evil-normal-state-map "gc" 'elscreen-create)
(define-key evil-normal-state-map "gd" 'elscreen-kill)
(define-key evil-normal-state-map "gj" 'elscreen-previous)
(define-key evil-normal-state-map "gk" 'elscreen-next)
(define-key evil-normal-state-map "gb" 'ibuffer-list-buffers) ; By association.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; The backups and auto-saves
(setq backup-directory-alist
      `((".*" . "~/.emacs-auto-backups")))

;;; This shit is stupid. I have tried all sorts of things to put it in one dir
;;; and it just keeps irking me. So fuck this.
(setq auto-save-default nil)

(setq kept-old-versions   5  ; Keep one old copy.
      kept-new-versions   5  ; Keep one new copy.
      )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Paren matching and autoclosing.

(show-paren-mode t)
(add-hook 'prog-mode-hook 'autopair-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Miscellaneous

;;; Follow the files symlinks link to by default
(setq vc-follow-symlinks t)

;;; Use a key for alignments
(evil-leader/set-key "al" 'align-regexp)

;;; Make scripts executable
(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)

;;; Add a newline above and below the cursor and enter insert mode.
(defun open-between-empty-lines ()
  "Create an empty line above and below the cursor and enter evil-insert-mode at
  cursor position."
  (interactive)
  (open-line 2)
  (next-line)
  (evil-insert-line 1))
(evil-leader/set-key "o" #'open-between-empty-lines)

;;; Delete all blank lines (or containing only whitespace)
(evil-leader/set-key "db"
  (lambda ()
    (interactive)
    (evil-ex "g:^\s*$:d<CR>")))

;;; Delete all trailing whitespace.
(evil-leader/set-key "dw"
  (lambda ()
    (interactive)
    (evil-ex "%s/\s\+$//e<CR>:let @/=''<CR>")))

;;; Reformat a paragraph.
(evil-leader/set-key "rf"
  (lambda ()
    (interactive)
    (mark-paragraph)
    (fill-paragraph)))

;;; Copy a paragraph to system clipboard.
(evil-leader/set-key "y"
  (lambda ()
    (interactive)
    (let* ((p (point)))
      (mark-paragraph)
      (clipboard-kill-ring-save (region-beginning) (region-end))
      (goto-char p)
      (message "Paragraph copied."))))

;;; Copy the whole buffer to system clipboard.
(evil-leader/set-key "Y"
  (lambda ()
    (interactive)
    (clipboard-kill-ring-save (point-min) (point-max))
    (message "Buffer copied.")))

;;; Move by visual lines and not by actual lines
(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)

;;; Use hide-show minor mode for code folding in all programming languages
(add-hook 'prog-mode-hook 'hs-minor-mode)

;;; Use y/n for asking instead of yes/no
(defalias 'yes-or-no-p 'y-or-n-p)

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Completion framework: Company

(add-hook 'after-init-hook 'global-company-mode)
(setq company-idle-delay nil) ; Do not complete unless I ask.
(setq company-selection-wrap-around t)
(define-key evil-insert-state-map (kbd "TAB") 'company-complete)
(eval-after-load 'company
  '(progn
     (define-key company-active-map [tab] 'company-select-next)
     (define-key company-active-map [backtab] 'company-select-previous)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Snippets
(require 'yasnippet) ; Not sure why this guy needs to be required explicitly. 
(yas-reload-all)
(add-hook 'prog-mode-hook #'yas-minor-mode)
(define-key yas-minor-mode-map [(tab)] nil)
(define-key yas-minor-mode-map (kbd "TAB") nil)
(define-key yas-minor-mode-map (kbd "<tab>") nil)
(define-key yas-minor-mode-map [backtab] 'yas-expand)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; PDF and other documents (ps, dvi, doc and shit)

;;; These keys allow you to scroll the pdf without leaving current buffer
;; http://www.idryman.org/blog/2013/05/20/emacs-and-pdf/
;; Also works with numeric prefix to scroll multiple pages at once

;; NB: Make sure to be using only two splits so that other-window 1 does
;; not get confused.

;; TODO: Find how to do this using a macro

(defun dvscroll-forward ()
  (interactive)
  (other-window 1)
  (image-next-line 1)
  (other-window 1))

(defun dvscroll-backward ()
  (interactive)
  (other-window 1)
  (image-previous-line 1)
  (other-window 1))

(defun dvscroll-previous-page ()
  (interactive)
  (other-window 1)
  (doc-view-previous-page)
  (other-window 1))

(defun dvscroll-next-page ()
  (interactive)
  (other-window 1)
  (doc-view-next-page)
  (other-window 1))

(defun dvscroll-first-page ()
  (interactive)
  (other-window 1)
  (doc-view-first-page)
  (other-window 1))

(defun dvscroll-last-page ()
  (interactive)
  (other-window 1)
  (doc-view-last-page)
  (other-window 1))

(defun dvscroll-goto-page (page)
  (interactive "nPage: ")
  (other-window 1)
  (doc-view-goto-page page)
  (other-window 1))

(evil-leader/set-key "ph" 'dvscroll-forward)
(evil-leader/set-key "pj" 'dvscroll-next-page)
(evil-leader/set-key "pk" 'dvscroll-previous-page)
(evil-leader/set-key "pl" 'dvscroll-backward)
(evil-leader/set-key "pg" 'dvscroll-first-page)
(evil-leader/set-key "pG" 'dvscroll-last-page)
(evil-leader/set-key "pn" 'dvscroll-goto-page)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Linting with Flycheck
(add-hook 'prog-mode-hook #'flycheck-mode)
(evil-leader/set-key "fl" 'flycheck-list-errors)

;;;; TODO: Packages & Functionality to explore
;;;  1. Helm
;;;  2. Org-mode
;;;  3. Magit
;;;  4. Projejctile (with helm)
;;;  5. ESS & R-autoyas
;;;  6. Markdown and latex with previews
;;;  7. Multiple-cursors
;;;  8. IPython interaction
;;;  9. Comment boxes
;;; 10. Read TRAMP documentation and configure
;;; 11. Read dired documentation and configure (What about dired-plus?)
;;; 12. What is all the ido, derivatives, & fl(e)x / smex business?