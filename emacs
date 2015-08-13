;;;; El-get
(add-to-list 'load-path "~/.emacs.d/el-get/el-get")

(unless (require 'el-get nil 'noerror)
  (with-current-buffer
      (url-retrieve-synchronously
       "https://raw.githubusercontent.com/dimitri/el-get/master/el-get-install.el")
    (goto-char (point-max))
    (eval-print-last-sexp)))

(add-to-list 'el-get-recipe-path "~/.emacs.d/el-get-user/recipes")
(el-get 'sync)

;;;; Evil and related packages
(require 'evil)

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
  "ci" 'evilnc-toggle-invert-comment-line-by-line)
;; TODO: Find a way to remove redundant mappings and change the operator mapping for this plugin.

(require 'evil-exchange)
(setq evil-exchange-key (kbd "gx"))
(setq evil-exchange-key (kbd "gX"))
(evil-exchange-install)

;;; Do this last
(evil-mode 1)
