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

;;;; Sync all packages at startup

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
   helm
   helm-ag
   jedi  ; jedi:install-server manually!
   magit
   markdown-mode
   org-mode
   projectile
   helm-projectile))

;;; Use this section for el-get packages that need to be bundled.
(el-get-bundle krisajenkins/evil-tabs)
(el-get-bundle emacsfodder/emacs-mainline)
;; This will also load the theme if standalone. For loading the theme when
;; running as a client, see the appearance section.
;; (el-get-bundle darktooth-theme in akhilsbehl/emacs-theme-darktooth)
(el-get-bundle atom-one-dark-theme in jonathanchu/atom-one-dark-theme)
(el-get-bundle gromnitsky/wordnut)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; The standard package manager for other stuff

;;; Packages not available through el-get or that break with el-get

(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.milkbox.net/packages/")))
(package-initialize)

(defun asb-require-package (pkg)
  (unless (package-installed-p pkg)
    (unless (assoc pkg package-archive-contents)
      (package-refresh-contents))
    (package-install pkg)))

;;; Use this section for packages that need to be installed from ELPA/MELPA.
(asb-require-package 'ess)
(asb-require-package 'flycheck)

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
(defun asb-transfer-key (from-keymap to-keymap key)
  "Moves key binding from one keymap to another, deleting from the old
   location."
  (define-key to-keymap key (lookup-key from-keymap key))
  (define-key from-keymap key nil))
(asb-transfer-key evil-motion-state-map evil-normal-state-map (kbd "RET"))
(asb-transfer-key evil-motion-state-map evil-normal-state-map " ")

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

;;; Window management

;; Drop this weird keymap since it interferes with evil.
(define-key evil-insert-state-map (kbd "C-w") 'evil-window-map)

;; ;; Evil already maps C-w hjkl to windmove. But let's make:
;; ; 1. C-w o to go the last window; and
(defun asb-previous-window ()
  (interactive)
  (other-window -1))
(define-key evil-window-map (kbd "o") 'asb-previous-window)

; 2. Make windomove cycle windows
(setq windmove-wrap-around t)

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
                (set-face-attribute 'default nil :font "Monaco 10"))))

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
(defun asb-open-between-empty-lines ()
  "Create an empty line above and below the cursor and enter evil-insert-mode at
  cursor position."
  (interactive)
  (open-line 2)
  (next-line)
  (evil-insert-line 1))
(evil-leader/set-key "o" #'asb-open-between-empty-lines)

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

;;; Copy the whole 'b'uffer to system clipboard.
(evil-leader/set-key "yb"
  (lambda ()
    (interactive)
    (clipboard-kill-ring-save (point-min) (point-max))
    (message "Buffer copied.")))

;;; Copy from beginning of the buffer 'u'pto point.
(evil-leader/set-key "yu"
  (lambda ()
    (interactive)
    (clipboard-kill-ring-save (point-min) (point))
    (message "Buffer copied upto point.")))

;;; Copy 'f'rom point to the end of buffer.
(evil-leader/set-key "yf" ; Copy the whole buffer to system clipboard
  (lambda ()
    (interactive)
    (clipboard-kill-ring-save (point) (point-max))
    (message "Buffer copied from point onwards.")))

;;; Move by visual lines and not by actual lines
(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)

;;; Use y/n for asking instead of yes/no
(defalias 'yes-or-no-p 'y-or-n-p)

;;; Make escape quit in the minibuffer too
(defun asb-minibuffer-keyboard-quit ()
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
(define-key minibuffer-local-map [escape] 'asb-minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'asb-minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'asb-minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'asb-minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'asb-minibuffer-keyboard-quit)
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
(defun asb-split-horizontal ()
  (interactive)
  (split-window-vertically)
  (other-window 1))

(defun asb-split-vertical ()
  (interactive)
  (split-window-horizontally)
  (other-window 1))

(evil-leader/set-key (kbd "-") 'asb-split-horizontal)
(evil-leader/set-key (kbd "|") 'asb-split-vertical)

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
(define-key ac-completing-map (kbd "C-h") 'ac-persist-help)
(define-key ac-completing-map (kbd "C-n") 'ac-quick-help-scroll-down)
(define-key ac-completing-map (kbd "C-p") 'ac-quick-help-scroll-up)

;; Deal with the linum display bug
(ac-linum-workaround)

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
(evil-leader/set-key "hM" 'helm-man-woman)
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

;;; TODO:
; 1. Find a way to send arbitrary commands on object at point.

(require 'ess-site)

(add-hook 'ess-mode-hook
          (lambda ()
            (setq ess-use-auto-complete t)
            (setq ess-style 'RRR+)
            (setq ess-R-argument-suffix "=")
            (ess-disable-smart-S-assign nil)
            (ess-disable-smart-underscore nil)))

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
(define-key evil-insert-state-map (kbd "C-e") nil)
(define-key inferior-ess-mode-map "," nil)

(define-key inferior-ess-mode-map (kbd "C-e ,") 'ess-smart-comma)
(define-key inferior-ess-mode-map (kbd "C-e q") 'ess-quit)
(define-key inferior-ess-mode-map (kbd "C-e f") 'ess-load-file)
(define-key inferior-ess-mode-map (kbd "C-e d") 'ess-use-this-dir)
(define-key inferior-ess-mode-map (kbd "C-e D") 'ess-set-working-directory)
(define-key inferior-ess-mode-map (kbd "C-e p") 'ess-install-library)
(define-key inferior-ess-mode-map (kbd "C-e P") 'ess-display-package-index)
(define-key inferior-ess-mode-map (kbd "C-e h") 'ess-display-help-on-object)
(define-key inferior-ess-mode-map (kbd "C-e H") 'ess-describe-object-at-point)
(define-key inferior-ess-mode-map (kbd "C-e t") 'ess-show-traceback)
(define-key inferior-ess-mode-map (kbd "C-e T") 'ess-show-call-stack)
(define-key inferior-ess-mode-map (kbd "C-e l")
  'ess-msg-and-comint-dynamic-list-input-ring)

;; Comint related stuff
(define-key inferior-ess-mode-map (kbd "C-e 0") 'comint-bol)
(define-key inferior-ess-mode-map (kbd "C-e j") 'comint-next-input)
(define-key inferior-ess-mode-map (kbd "C-e k") 'comint-previous-input)
(define-key inferior-ess-mode-map (kbd "C-e J") 'comint-next-prompt)
(define-key inferior-ess-mode-map (kbd "C-e K") 'comint-previous-prompt)
(define-key inferior-ess-mode-map (kbd "C-e ?")
  'comint-history-isearch-backward-regexp)
(define-key inferior-ess-mode-map (kbd "<up>")
  'comint-next-matching-input-from-input)
(define-key inferior-ess-mode-map (kbd "<down>")
  'comint-previous-matching-input-from-input)

;; Inspiration:
;; blogisticreflections.wordpress.com/2009/10/01/r-object-tooltips-in-ess/

(defun asb-ess-R-object-popup (r-func)
  "R-FUNC: The R function to use on the object.
Run R-FUN for object at point, and display results in a popup."
  (let ((objname (current-word))
        (curbuf (current-buffer))
        (tmpbuf (get-buffer-create "**ess-R-object-popup**")))
    (if objname
        (progn
          (ess-command (concat "class(" objname ")\n")  tmpbuf)
          (set-buffer tmpbuf)
          (let ((bs (buffer-string)))
            (if (not(string-match "\(object .* not found\)\|unexpected" bs))
                (progn
                  (message (concat r-func "(" objname ")\n"))
                  (ess-command (concat r-func "(" objname ")\n") tmpbuf)
                  (let ((bs (buffer-string)))
                    (progn
                      (set-buffer curbuf)
                      (popup-tip bs))))))))
    (kill-buffer tmpbuf)))

(defun asb-ess-R-object-str-popup-str (asb-ess-R-object-popup "str"))

(defun asb-ess-R-object-popup-interactive (r-func)
  (interactive "sR function to execute: ")
  (asb-ess-R-object-popup r-func))

(evil-leader/set-key-for-mode 'ess-mode "ei" 'asb-ess-R-object-popup-str)
(evil-leader/set-key-for-mode 'ess-mode "eI"
  'asb-ess-R-object-popup-interactive)

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

(cl-defun asb-set-python-debugger-trace
    (&optional (statement "import pdb; pdb.set_trace()"))
  (interactive)
  (move-beginning-of-line 1)
  (next-line 1)
  (open-line 1)
  (insert statement)
  (python-indent-line))
(evil-leader/set-key-for-mode 'python-mode "da" 'asb-set-python-debugger-trace)

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
            (auto-complete-mode)
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

(defun asb-time-now ()
  (interactive)
  (insert (format-time-string "%A, %B %d, %Y %H:%M:%S")))

(defun asb-date-today ()
  (interactive)
  (insert (format-time-string "%A, %B %d, %Y")))

(evil-leader/set-key "it" 'asb-time-now)
(evil-leader/set-key "id" 'asb-date-today)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Smerge mode

;;; http://emacs.stackexchange.com/questions/16469/how-to-merge-
;;; git-conflicts-in-emacs

(evil-leader/set-key "sn" 'smerge-next)
(evil-leader/set-key "sp" 'smerge-previous)
(evil-leader/set-key "skc" 'smerge-keep-current)
(evil-leader/set-key "skb" 'smerge-keep-base)
(evil-leader/set-key "skm" 'smerge-keep-mine)
(evil-leader/set-key "sko" 'smerge-keep-other)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; WordNut: Searching the WordNet DB

(evil-leader/set-key "wl" 'wordnut-lookup-current-word)
(evil-leader/set-key "ws" 'wordnut-search)

(add-hook 'wordnut-mode-hook
          (lambda ()
            (define-key
              wordnut-mode-map (kbd "/") 'wordnut-search)
            (define-key
              wordnut-mode-map (kbd "RET") 'wordnut-lookup-current-word)
            (define-key
              wordnut-mode-map (kbd "o") 'wordnut-show-overview)
            (define-key
              wordnut-mode-map (kbd "h") 'wordnut-history-backward)
            (define-key
              wordnut-mode-map (kbd "l") 'wordnut-history-forward)
            (define-key
              wordnut-mode-map (kbd "H") 'wordnut-history-lookup)
            (define-key
              wordnut-mode-map (kbd "k") 'outline-previous-visible-heading)
            (define-key
              wordnut-mode-map (kbd "j") 'outline-next-visible-heading)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; TODO: Packages & Functionality to explore

;;; 0. A good snippet system. Please.
;;; 1. Org-mode (Too much too much!)
;;; 2. Multiple cursors
;;; 3. IPython interaction: anything better than Elpy to send commands?
;;; 4. ETags bitch! Seriously.
