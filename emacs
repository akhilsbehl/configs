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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; The standard package manager for other stuff

(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.milkbox.net/packages/")))
(package-initialize)

(defun require-package (pkg)
  (unless (package-installed-p pkg)
    (unless (assoc pkg package-archive-contents)
      (package-refresh-contents))
    (package-install pkg)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Sync all packages at startup

;;; This section is to deal with some deps that cause breakage from time to
;;; time. Ideally this should be empty.
;; (el-get 'sync 'foo)
;; (require-package 'bar)

;;; Use this section for standard edition el-get packages
(el-get
 'sync
 '(auto-complete
   elscreen
   evil
   evil-exchange
   evil-leader
   evil-nerd-commenter
   evil-numbers
   evil-surround
   flycheck
   helm
   helm-ag
   jedi  ; jedi:install-server manually!
   magit
   markdown-mode
   org-mode
   projectile))

;;; Use this section for packages that need to be installed from ELPA/MELPA.
(require-package 'ess)  ;; Till it starts working with el-get

;;; Use this section for el-get packages that need to be bundled.

(el-get-bundle krisajenkins/evil-tabs)
(el-get-bundle emacsfodder/emacs-mainline)
;; This will also load the theme if standalone. For loading the theme when
;; running as a client, see the appearance section.
(el-get-bundle darktooth-theme in akhilsbehl/emacs-theme-darktooth)

;;; Use this section for packages that need to be installed using `package`

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Evil and related packages

;;; Do not let some of the modes over-ride evil
(custom-set-variables
 '(evil-intercept-maps nil)
 '(evil-overriding-maps nil))

;;; Search symbols and not words
(setq-default evil-symbol-word-search t)

;;; Let everything open up in Evil motion (normal?) mode.
(setq evil-motion-state-modes (append evil-emacs-state-modes
                                      evil-motion-state-modes))
(setq evil-emacs-state-modes nil)

;;; http://www.emacswiki.org/emacs/Evil
(defun transfer-key (from-keymap to-keymap key)
  "Moves key binding from one keymap to another, deleting from the old
   location."
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
(evil-leader/set-key "ct" 'evilnc-comment-or-uncomment-lines)
(evil-leader/set-key "ci" 'evilnc-toggle-invert-comment-line-by-line)
(evil-leader/set-key "cb" #'comment-box) ; Here by association

;;; Swap selections / text-objects
(evil-exchange-install)

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

;;; Main-line mode bar
(require 'main-line)
(setq main-line-separator-style 'wave)

;;; Colortheme and font in daemon mode.
;; http://stackoverflow.com/questions/18904529/
;; after-emacs-deamon-i-can-not-see-new-theme-in-emacsclient-frame-it-works-fr
(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (select-frame frame)
                (set-face-attribute 'default nil :font "Monaco 10")
                (load-theme 'darktooth t))))

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
(setq evil-replace-state-cursor '("red" hollow))

;;; Visually indicate the right limit for programming modes
(require 'whitespace)
(setq whitespace-line-column 80)
(setq whitespace-style '(face trailing lines-tail tab-mark))
(add-hook 'prog-mode-hook 'whitespace-mode)

;;; Always show matching parens
(show-paren-mode t)

;;; Scroll by lines and not by half a page.
(setq scroll-step 1)
(setq scroll-conservatively 101)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Use vim-like tabs (also using krisajenkins' evil-tabs)
(load "elscreen" "ElScreen" t)
(add-hook 'evil-local-mode-hook (lambda () (evil-tabs-mode 1)))

;;; Do the same for the hybrid state map
(evil-leader/set-key (kbd "tc") 'elscreen-create)
(evil-leader/set-key (kbd "td") 'elscreen-kill)
(evil-leader/set-key (kbd "tj") 'elscreen-previous)
(evil-leader/set-key (kbd "tk") 'elscreen-next)
(evil-leader/set-key (kbd "tt") 'evil-tabs-current-buffer-to-tab)
(evil-leader/set-key (kbd "tT") 'elscreen-find-and-goto-by-buffer)
(evil-leader/set-key (kbd "t=") 'balance-windows)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; The backups and auto-saves
(setq backup-directory-alist
      `((".*" . "~/.emacs-auto-backups")))

;;; This shit is stupid. I have tried all sorts of things to put it in one dir
;;; and it just keeps irking me. So fuck this.
(setq auto-save-default nil)

(setq
 kept-old-versions 5
 kept-new-versions 5)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Miscellaneous

;;; Follow symlinks by default
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
(evil-leader/set-key "db" ; Delete all blank lines
  (lambda ()
    (interactive)
    (evil-ex "g:^\s*$:d<CR>")))

;;; Delete all trailing whitespace.
(evil-leader/set-key "dw" ; Delete all trailing whitespace
  (lambda ()
    (interactive)
    (evil-ex "%s/\s\+$//e<CR>:let @/=''<CR>")))

;; Kill the current buffer only
(evil-leader/set-key "kb" 'kill-buffer)
;; Kill the current buffer and window
(evil-leader/set-key "kB" 'kill-buffer-and-window)
;; Kill the current window
(evil-leader/set-key "kw" 'delete-window)
;; Kill all windows except current
(evil-leader/set-key "kW" 'delete-other-windows)
;; Kill the current frame
(evil-leader/set-key "kf" 'delete-frame)
;; Kill the current tab
(define-key evil-normal-state-map "kt" 'elscreen-kill)

;;; Reformat a paragraph.
(evil-leader/set-key "rf" ; Reformat a paragraph
  (lambda ()
    (interactive)
    (fill-paragraph)))

;;; Copy a paragraph to system clipboard.
(evil-leader/set-key "y" ; Copy a paragraph to system clipboard
  (lambda ()
    (interactive)
    (let* ((p (point)))
      (mark-paragraph)
      (clipboard-kill-ring-save (region-beginning) (region-end))
      (goto-char p)
      (message "Paragraph copied."))))

;;; Copy the whole buffer to system clipboard.
(evil-leader/set-key "Y" ; Copy the whole buffer to system clipboard
  (lambda ()
    (interactive)
    (clipboard-kill-ring-save (point-min) (point-max))
    (message "Buffer copied.")))

;;; Move by visual lines and not by actual lines
(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)

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

(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)
(global-set-key [escape] 'evil-exit-emacs-state)

;;; Open ibuffer when I want it
(evil-leader/set-key "b" 'ibuffer)

;;; Browse in firefox
(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "firefox")

;;; Revert buffers easily
(evil-leader/set-key "rb" 'revert-buffer)

;;; Evaluate an sexp.
(evil-leader/set-key "els" 'eval-last-sexp)

;;; Github/Chalmagean/emacs.d/my-evil.el
(defun split-horizontal ()
  (interactive)
  (split-window-vertically)
  (other-window 1))

(defun split-vertical ()
  (interactive)
  (split-window-horizontally)
  (other-window 1))

(evil-leader/set-key (kbd "-") 'split-horizontal)
(evil-leader/set-key (kbd "|") 'split-vertical)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Some niceties to work with undo-tree

(evil-leader/set-key "uv" 'undo-tree-visualize)
(evil-leader/set-key "ud" 'undo-tree-visualizer-toggle-diff)
(evil-leader/set-key "ua" 'undo-tree-visualizer-abort)
(evil-leader/set-key "uq" 'undo-tree-visualizer-quit)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; HideShow mode bindings.

;;; Use hide-show minor mode for code folding in all programming languages
(add-hook 'prog-mode-hook 'hs-minor-mode)

;;; Unset what evil comes with.
(define-key evil-normal-state-map (kbd "z a") nil)
(define-key evil-normal-state-map (kbd "z o") nil)
(define-key evil-normal-state-map (kbd "z O") nil)
(define-key evil-normal-state-map (kbd "z c") nil)
(define-key evil-normal-state-map (kbd "z r") nil)
(define-key evil-normal-state-map (kbd "z m") nil)

;;; Now set up my own.
(define-key evil-normal-state-map (kbd "z t") 'hs-toggle-hiding)
(define-key evil-normal-state-map (kbd "z h") 'hs-hide-all)
(define-key evil-normal-state-map (kbd "z s") 'hs-show-all)
(define-key evil-normal-state-map (kbd "z l") 'hs-hide-level)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Completion framework: Auto-complete

(ac-config-default)

(setq-default ac-sources '(ac-source-words-in-buffer
                           ac-source-words-in-same-mode-buffers
                           ac-source-filename
                           ac-source-abbrev))

(setq ac-use-quick-help t)
(setq ac-quick-help-delay 1)
(setq ac-set-trigger-key "TAB")
(setq ac-auto-start 3)
(setq ac-ignore-case 'smart)
(setq ac-auto-show-menu 0.8)
(setq ac-menu-height 20)
(setq ac-ignore-case nil)

(define-key ac-mode-map (kbd "TAB") 'auto-complete)
(define-key ac-completing-map (kbd "C-j") 'ac-next)
(define-key ac-completing-map (kbd "C-k") 'ac-previous)
(define-key ac-completing-map (kbd "C-h") 'ac-help)
(define-key ac-completing-map (kbd "C-H") 'ac-persist-help)
(define-key ac-completing-map (kbd "C-n") 'ac-quick-help-scroll-up)
(define-key ac-completing-map (kbd "C-p") 'ac-quick-help-scroll-down)

;; Deal with the linum display bug
(ac-linum-workaround)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; PDF and other documents (ps, dvi, doc and shit)

;;; Automatically update my docs without confirmation when they change on disk
(add-hook 'doc-view-mode 'auto-revert-mode)

;;; These keys allow you to scroll the pdf without leaving current buffer
;; http://www.idryman.org/blog/2013/05/20/emacs-and-pdf/
;; Also works with numeric prefix to scroll multiple pages at once

;; NB: Make sure to be using only two splits so that `(other-window 1)' does
;; not get confused.

(defun dvscroll-forward ()
  (interactive)
  (other-window 1)
  (image-next-line 3)
  (other-window 1))

(defun dvscroll-backward ()
  (interactive)
  (other-window 1)
  (image-previous-line 3)
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

(evil-leader/set-key-for-mode 'doc-view-mode "Ph" 'dvscroll-forward)
(evil-leader/set-key-for-mode 'doc-view-mode "Pj" 'dvscroll-next-page)
(evil-leader/set-key-for-mode 'doc-view-mode "Pk" 'dvscroll-previous-page)
(evil-leader/set-key-for-mode 'doc-view-mode "Pl" 'dvscroll-backward)
(evil-leader/set-key-for-mode 'doc-view-mode "Pg" 'dvscroll-first-page)
(evil-leader/set-key-for-mode 'doc-view-mode "PG" 'dvscroll-last-page)
(evil-leader/set-key-for-mode 'doc-view-mode "Pn" 'dvscroll-goto-page)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Linting with Flycheck
(add-hook 'prog-mode-hook #'flycheck-mode)
(setq flycheck-display-errors-delay 1)

(evil-leader/set-key "fv" 'flycheck-verify-setup)
(evil-leader/set-key "fc" 'flycheck-buffer)
(evil-leader/set-key "fl" 'flycheck-list-errors)
(evil-leader/set-key "ff" 'flycheck-first-error)
(evil-leader/set-key "fn" 'flycheck-next-error)
(evil-leader/set-key "fp" 'flycheck-previous-error)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Helm

(require 'helm-config)

;; Tramp breaks helm. See: https://github.com/emacs-helm/helm/issues/1000
(setq tramp-ssh-controlmaster-options
      "-o ControlMaster=auto -o ControlPath='tramp.%%C' -o ControlPersist=no")
(helm-mode 1)

(setq helm-M-x-fuzzy-match t)

;;; Invoke various kind of completions
(global-unset-key (kbd "C-x c"))
(evil-leader/set-key "hx" 'helm-M-x)
(evil-leader/set-key "hf" 'helm-find-files)
(evil-leader/set-key "hb" 'helm-mini)
(evil-leader/set-key "hm" 'helm-all-mark-rings)
(evil-leader/set-key "hk" 'helm-show-kill-ring)
(evil-leader/set-key "hg" 'helm-do-grep-ag)

;;; For when in completion mode
(setq helm-move-to-line-cycle-in-source t
      helm-ff-file-name-history-use-recentf t)
(when (executable-find "ack")
  (setq helm-grep-default-command
        "ack -Hn --no-group --no-color %e %p %f"
        helm-grep-default-recurse-command
        "ack -H --no-group --no-color %e %p %f"))

(define-key helm-map (kbd "C-j") 'helm-next-line)
(define-key helm-map (kbd "C-k") 'helm-previous-line)
(define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action)
(define-key helm-map (kbd "<backtab>") 'helm-select-action)
(define-key helm-map (kbd "C-.") 'helm-toggle-visible-mark)
(define-key helm-map (kbd "C-a") 'helm-toggle-all-marks)
(define-key helm-map (kbd "C-i") 'helm-copy-to-buffer)
(define-key helm-map (kbd "C-h") 'helm-help)
(define-key helm-map (kbd "C-y") 'next-history-element)
(define-key helm-map (kbd "C-Y") 'helm-yank-text-at-point)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Projectile mode

(require 'helm-projectile)
(projectile-global-mode)
(setq projectile-completion-system 'helm)
(setq projectile-switch-project-action 'helm-projectile)
(setq projectile-enable-caching t)
(evil-leader/set-key "pp" 'helm-projectile)
(evil-leader/set-key "pf" 'helm-projectile-find-file)
(evil-leader/set-key "pF" 'helm-projectile-find-file-in-known-projects)
(evil-leader/set-key "pd" 'helm-projectile-find-dir)
(evil-leader/set-key "pr" 'helm-projectile-find-recentf)
(evil-leader/set-key "pb" 'helm-projectile-switch-to-buffer)
(evil-leader/set-key "pg" 'helm-projectile-ag)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Magit

(evil-leader/set-key "gs" 'magit-status)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Org-mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; ESS

(require 'ess-site)

;;; ESS editing mode
(evil-leader/set-key-for-mode 'ess-mode "eq" 'ess-quit)
(evil-leader/set-key-for-mode 'ess-mode "ef" 'ess-load-file)
(evil-leader/set-key-for-mode 'ess-mode "ed" 'ess-use-this-dir)
(evil-leader/set-key-for-mode 'ess-mode "eD" 'ess-set-working-directory)
(evil-leader/set-key-for-mode 'ess-mode "ep" 'ess-install-library)
(evil-leader/set-key-for-mode 'ess-mode "eP" 'ess-display-package-index)
(evil-leader/set-key-for-mode 'ess-mode "eb" 'ess-eval-buffer)
(evil-leader/set-key-for-mode 'ess-mode "el" 'ess-eval-line-and-step)
(evil-leader/set-key-for-mode 'ess-mode "eg" 'ess-eval-buffer-from-beg-to-here)
(evil-leader/set-key-for-mode 'ess-mode "eG" 'ess-eval-buffer-from-here-to-end)
(evil-leader/set-key-for-mode 'ess-mode "ex"
  'ess-eval-region-or-function-or-paragraph-and-step)
(evil-leader/set-key-for-mode 'ess-mode "eB" 'ess-force-buffer-current)
(evil-leader/set-key-for-mode 'ess-mode "eh" 'ess-display-help-on-object)
(evil-leader/set-key-for-mode 'ess-mode "eH" 'ess-describe-object-at-point)
(evil-leader/set-key-for-mode 'ess-mode "et" 'ess-show-traceback)
(evil-leader/set-key-for-mode 'ess-mode "eT" 'ess-show-call-stack)

;;; inferior ESS execution mode
(evil-leader/set-key-for-mode 'inferior-ess-mode "eq" 'ess-quit)
(evil-leader/set-key-for-mode 'inferior-ess-mode "ef" 'ess-load-file)
(evil-leader/set-key-for-mode 'inferior-ess-mode "eD" 'ess-set-working-directory)
(evil-leader/set-key-for-mode 'inferior-ess-mode "ep" 'ess-install-library)
(evil-leader/set-key-for-mode 'inferior-ess-mode "eP" 'ess-display-package-index)
(evil-leader/set-key-for-mode 'inferior-ess-mode "e<tab>" 'ess-list-object-completions)
(evil-leader/set-key-for-mode 'inferior-ess-mode "eh" 'ess-display-help-on-object)
(evil-leader/set-key-for-mode 'inferior-ess-mode "eH" 'ess-describe-object-at-point)
(evil-leader/set-key-for-mode 'inferior-ess-mode "et" 'ess-show-traceback)
(evil-leader/set-key-for-mode 'inferior-ess-mode "eT" 'ess-show-call-stack)
(evil-leader/set-key-for-mode 'inferior-ess-mode "el"
  'ess-msg-and-comint-dynamic-list-input-ring)

;; Comint related stuff
(evil-leader/set-key-for-mode 'inferior-ess-mode "ej" 'comint-next-input)
(evil-leader/set-key-for-mode 'inferior-ess-mode "ek" 'comint-previous-input)
(setq comint-prompt-regexp t)
(evil-leader/set-key-for-mode 'inferior-ess-mode "eh" 'comint-next-prompt)
(evil-leader/set-key-for-mode 'inferior-ess-mode "el" 'comint-previous-prompt)
(evil-leader/set-key-for-mode 'inferior-ess-mode "es"
  'comint-history-isearch-backward-regexp)
(evil-leader/set-key-for-mode 'inferior-ess-mode "eJ"
  'comint-next-matching-input-from-input)
(evil-leader/set-key-for-mode 'inferior-ess-mode "eK"
  'comint-previous-matching-input-from-input)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Python set-up

(add-hook 'python-mode-hook
          (lambda ()
            (jedi:setup)
            (setq jedi:complete-on-dot t)
            (setq jedi:get-in-function-call-delay 1000)
            (setq jedi:goto-definition-marker-ring-length 32)))

(evil-leader/set-key-for-mode 'python-mode "jh" 'jedi:show-doc)
(evil-leader/set-key-for-mode 'python-mode "jg" 'jedi:goto-definition)
(evil-leader/set-key-for-mode 'python-mode
  "jG" 'jedi:goto-definition-pop-marker)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Markdown mode

;;; http://jblevins.org/projects/markdown-mode/
(autoload 'markdown-mode "markdown-mode"
   "Major mode for editing Markdown files" t)
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

;;; Using Firefox auto-reload extension, this will automatically regenerate the
;;; markdown to html and refresh it in the browser on each buffer write.
(add-hook 'markdown-mode-hook
          (lambda ()
            (setq markdown-command "md2html")
            ; Only work on the one markdown buffer
            (add-hook 'after-save-hook 'markdown-export nil 'local)
            ; Use this for opening the preview
            (evil-leader/set-key-for-mode
              'markdown-mode "mp" 'markdown-export-and-preview)
            ; Use this for manual refreshes
            (evil-leader/set-key-for-mode
              'markdown-mode "me" 'markdown-export)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Insert date & time

;;; http://stackoverflow.com/questions/251908/how-can-i-insert-current-date-and
;;; -time-into-a-file-using-emacs

(defun time-now ()
  (interactive)
  (insert (format-time-string "%A, %B %d, %Y %H:%M:%S")))

(defun date-today ()
  (interactive)
  (insert (format-time-string "%A, %B %d, %Y")))

(evil-leader/set-key "it" 'time-now)
(evil-leader/set-key "id" 'date-today)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; TODO: Packages & Functionality to explore

;;; 1. Org-mode (Too much too much!)
;;; 2. ESS
;;; 3. Multiple cursors
;;; 4. IPython interaction: anything better than Elpy to send commands?
;;; 5. ETags bitch! Seriously.
