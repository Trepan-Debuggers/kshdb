;;; kshdb.el --- ksh Debugger mode via GUD and kshdb
;;; $Id: kshdb.el,v 1.43 2007/11/30 01:58:43 rockyb Exp $

;; Copyright (C) 2002, 2006, 2007, 2008 Rocky Bernstein (rocky@gnu.org) 
;;                    and Masatake YAMATO (jet@gyve.org)

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; Commentary:
;; 1. Add
;;
;;      (autoload 'kshdb "kshdb" "BASH Debugger mode via GUD and kshdb" t)
;;
;;    to your .emacs file.
;;
;; 2. Do M-x kshdb
;;
;; 3. Give a target script for debugging and arguments for it
;;    See `kshdb' of describe-function for more details.
;;    
;;
(if (< emacs-major-version 22)
  (error
   "This version of kshdb.el needs at least Emacs 22 or greater - you have version %d."
   emacs-major-version))

(require 'gud)


;; User-definable variables
;; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

(defcustom gud-kshdb-command-name "kshdb -A 3"
  "File name for executing bash debugger."
  :type 'string
  :group 'gud)

(defcustom kshdb-temp-directory
  (let ((ok '(lambda (x)
	       (and x
		    (setq x (expand-file-name x)) ; always true
		    (file-directory-p x)
		    (file-writable-p x)
		    x))))
    (or (funcall ok (getenv "TMPDIR"))
	(funcall ok "/usr/tmp")
	(funcall ok "/tmp")
	(funcall ok "/var/tmp")
	(funcall ok  ".")
	(error
	 "Couldn't find a usable temp directory -- set `kshdb-temp-directory'")))
  "*Directory used for temporary files created by a *gud-kshdb* process.
By default, the first directory from this list that exists and that you
can write into: the value (if any) of the environment variable TMPDIR,
/usr/tmp, /tmp, /var/tmp, or the current directory."
  :type 'string
  :group 'kshdb)

(defcustom kshdb-many-windows t
  "*If non-nil, display secondary kshdb windows, in a layout similar to `gdba'.
However only set to the multi-window display if the kshdb
command invocation has an annotate options (\"--annotate 3\" or \"-A 3\")."
  :type 'boolean
  :group 'kshdb)

(defcustom kshdbtrack-do-tracking-p nil
  "*Controls whether the kshdbtrack feature is enabled or not.
When non-nil, kshdbtrack is enabled in all comint-based buffers,
e.g. shell buffers and the *gud-kshdb* buffer.  When using kshdb to debug a
bash program, kshdbtrack notices the kshdb prompt and displays the
source file and line that the program is stopped at, much the same way
as gud-mode does for debugging C programs with gdb."
  :type 'boolean
  :group 'kshdb)
(make-variable-buffer-local 'kshdbtrack-do-tracking-p)

(defcustom kshdbtrack-minor-mode-text " kshdb"
  "*String to use in the minor mode list when kshdbtrack is enabled."
  :type 'string
  :group 'kshdb)

(defgroup kshdbtrack nil
  "Kshdb file tracking by watching the prompt."
  :prefix "kshdbtrack-"
  :group 'shell)


;; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;; NO USER DEFINABLE VARIABLES BEYOND THIS POINT

;; have to bind kshdb-file-queue before installing the kill-emacs-hook
(defvar kshdb-file-queue nil
  "Queue of Makefile temp files awaiting execution.
Currently-active file is at the head of the list.")

(defvar kshdbtrack-is-tracking-p nil)


;; Constants

(defconst kshdb-position-re 
  "\\(^\\|\n\\)(\\([^:]+\\):\\([0-9]*\\))"
  "Regular expression for a kshdb position")

(defconst kshdb-marker-regexp-file-group 2
  "Group position in kshdb-position-re that matches the file name.")

(defconst kshdb-marker-regexp-line-group 3
  "Group position in kshdb-position-re that matches the line number.")

(defconst kshdb-traceback-line-re
  "^#[0-9]+[ \t]+\\((\\([a-zA-Z-.]+\\) at (\\(\\([a-zA-Z]:\\)?[^:\n]*\\):\\([0-9]*\\)).*\n"
  "Regular expression that describes tracebacks.")

;; kshdbtrack constants
(defconst kshdbtrack-stack-entry-regexp
  "^->#[0-9]+[ \t]+\\((\\([a-zA-Z-.]+\\) at (\\(\\([a-zA-Z]:\\)?[^:\n]*\\):\\([0-9]*\\)).*\n"
  "Regular expression kshdbtrack uses to find a stack trace entry.")

(defconst kshdbtrack-input-prompt "\nkshdb<+.*>+ "
  "Regular expression kshdbtrack uses to recognize a kshdb prompt.")

(defconst kshdbtrack-track-range 10000
  "Max number of characters from end of buffer to search for stack entry.")

(defconst gud-kshdb-marker-regexp-file-group 1
  "Group position in `gud-kshdb-marker-regexp' that matches the file name.")
(defconst gud-kshdb-marker-regexp-line-group 2
  "Group position in `gud-kshdb-marker-regexp' that matches the line number.")

(defconst kshdb-annotation-start-regexp
  "\\([a-z]+\\)\n")
(defconst kshdb-annotation-end-regexp
  "\n")

;;; History of argument lists passed to kshdb.
(defvar gud-kshdb-history nil)

;; The debugger outputs program-location lines that look like this:
;;   (/etc/init.d/network:14):
(defconst gud-kshdb-marker-regexp
  "^(\\(\\(?:[a-zA-Z]:\\)?[-a-zA-Z0-9_/.\\\\ ]+\\):[ \t]?\\(.*\n\\)"
  "Regular expression used to find a file location given by kshdb.

Program-location lines look like this:
   (/etc/init.d/network:39):
or MS Windows:
   (c:\\mydirectory\\gcd.sh:10):
")

;; ======================================================================
;; kshdb functions

;; Convert a command line as would be typed normally to run a script
;; into one that invokes an Emacs-enabled debugging session.
;; "--debugger" in inserted as the first switch, unless the 
;; command is kshdb which doesn't need and can't parse --debugger.
;; Note: kshdb will be fixed up so that it *does* pass --debugger
;; eventually.

(defun gud-kshdb-massage-args (file args &optional command-line)
  (let* ((new-args (list "--debugger"))
	 (shift (lambda ()
		  (setq new-args (cons (car args) new-args))
		  (setq args (cdr args)))))

    ; If we are invoking using the kshdb command, no need to add
    ; --debugger. '^\S ' means non-whitespace at the beginning of a
    ; line and '\s ' means "whitespace"
    (if (and command-line (string-match "^\\S *kshdb\\s " command-line))
	args
    
      ;; Pass all switches and -e scripts through.
      (while (and args
		  (string-match "^-" (car args))
		  (not (equal "-" (car args)))
		  (not (equal "--" (car args))))
	(funcall shift))
      
      (when (or (not args)
		(string-match "^-" (car args)))
	  (error "Can't use stdin as the script to debug"))
      ;; This is the program name.
      (funcall shift)
      
      (while args
	(funcall shift))
      
      (nreverse new-args))))

;; There's no guarantee that Emacs will hand the filter the entire
;; marker at once; it could be broken up across several strings.  We
;; might even receive a big chunk with several markers in it.  If we
;; receive a chunk of text which looks like it might contain the
;; beginning of a marker, we save it here between calls to the
;; filter.
(defun gud-kshdb-marker-filter (string)
  ;;(message "GOT: %s" string)
  (setq gud-marker-acc (concat gud-marker-acc string))
  ;;(message "ACC: %s" gud-marker-acc)
  (let ((output "") s s2 (tmp ""))

    ;; ALB first we process the annotations (if any)
    (while (setq s (string-match kshdb-annotation-start-regexp
                                 gud-marker-acc))
      (let ((name (substring gud-marker-acc (match-beginning 1) (match-end 1)))
            (end (match-end 0)))
        (if (setq s2 (string-match kshdb-annotation-end-regexp
                                   gud-marker-acc end))
            ;; ok, annotation complete, process it and remove it
            (let ((contents (substring gud-marker-acc end s2))
                  (end2 (match-end 0)))
              (kshdb-process-annotation name contents)
              (setq gud-marker-acc
                    (concat (substring gud-marker-acc 0 s)
                            (substring gud-marker-acc end2))))
          ;; otherwise, save the partial annotation to a temporary, and re-add
          ;; it to gud-marker-acc after normal output has been processed
          (setq tmp (substring gud-marker-acc s))
          (setq gud-marker-acc (substring gud-marker-acc 0 s)))))
    
    (when (setq s (string-match kshdb-annotation-end-regexp gud-marker-acc))
      ;; save the beginning of gud-marker-acc to tmp, remove it and restore it
      ;; after normal output has been processed
      (setq tmp (substring gud-marker-acc 0 s))
      (setq gud-marker-acc (substring gud-marker-acc s)))
           
    ;; Process all the complete markers in this chunk.
    ;; Format of line looks like this:
    ;;   (/etc/init.d/ntp.init:16):
    ;; but we also allow DOS drive letters
    ;;   (d:/etc/init.d/ntp.init:16):
    (while (string-match gud-kshdb-marker-regexp gud-marker-acc)
      (setq

       ;; Extract the frame position from the marker.
       gud-last-frame
       (cons (substring gud-marker-acc 
			(match-beginning gud-kshdb-marker-regexp-file-group) 
			(match-end gud-kshdb-marker-regexp-file-group))
	     (string-to-number
	      (substring gud-marker-acc
			 (match-beginning gud-kshdb-marker-regexp-line-group)
			 (match-end gud-kshdb-marker-regexp-line-group))))

       ;; Append any text before the marker to the output we're going
       ;; to return - we don't include the marker in this text.
       output (concat output
		      (substring gud-marker-acc 0 (match-beginning 0)))

       ;; Set the accumulator to the remaining text.
       gud-marker-acc (substring gud-marker-acc (match-end 0))))

    ;; Does the remaining text look like it might end with the
    ;; beginning of another marker?  If it does, then keep it in
    ;; gud-marker-acc until we receive the rest of it.  Since we
    ;; know the full marker regexp above failed, it's pretty simple to
    ;; test for marker starts.
    (if (string-match "\032.*\\'" gud-marker-acc)
	(progn
	  ;; Everything before the potential marker start can be output.
	  (setq output (concat output (substring gud-marker-acc
						 0 (match-beginning 0))))

	  ;; Everything after, we save, to combine with later input.
	  (setq gud-marker-acc
		(concat tmp (substring gud-marker-acc (match-beginning 0)))))

      (setq output (concat output gud-marker-acc)
	    gud-marker-acc tmp))

    output))

(defvar kshdb--annotation-setup-map
  (progn
    (define-hash-table-test 'str-hash 'string= 'sxhash)
    (let ((map (make-hash-table :test 'str-hash)))
      (puthash "breakpoints" 'kshdb--setup-breakpoints-buffer map)
      (puthash "stack" 'kshdb--setup-stack-buffer map)
      ; (puthash "locals" 'kshdb--setup-locals-buffer map)
      map)))

(defun kshdb-process-annotation (name contents)
  (let ((buf (get-buffer-create (format "*kshdb-%s-%s*" name gud-target-name))))
    (with-current-buffer buf
      (setq buffer-read-only t)
     (let ((inhibit-read-only t)
            (setup-func (gethash name kshdb--annotation-setup-map)))
        (erase-buffer)
        (insert contents)
        (when setup-func (funcall setup-func buf))))))

(defun gud-kshdb-find-file (f)
  (save-excursion
    (let ((buf (find-file-noselect f 'nowarn)))
      (set-buffer buf)
      buf)))

(defun kshdb-get-script-name (args &optional annotate-p)
  "Pick out the script name from the command line and return a list of that and whether
the annotate option was set. Initially annotate should be set to nil."
  (let ((arg (pop args)))
     (cond 
      ((not arg) (list nil annotate-p))
      ((member arg '("-A" "--annotate"))
       (if args (kshdb-get-script-name (cdr args) t) '(nil t)))
      ((member arg '("-L" "--library" "T" "--terminal" "-t"
		    "--termdir" "-x"))
	      (if args 
		  (kshdb-get-script-name (cdr args) annotate-p)
		;else
		(list nil annotate-p)))
     ((string-match "^-[a-zA-z]" arg) (kshdb-get-script-name args annotate-p))
     ((string-match "^--[a-zA-z]+" arg) (kshdb-get-script-name args annotate-p))
     ((string-match "^kshdb" arg) (kshdb-get-script-name args annotate-p))
     ; found script name (or nil
     (t (list arg annotate-p)))))

; From Emacs 23
(unless (fboundp 'split-string-and-unquote)
  (defun split-string-and-unquote (string &optional separator)
  "Split the STRING into a list of strings.
It understands Emacs Lisp quoting within STRING, such that
  (split-string-and-unquote (combine-and-quote-strings strs)) == strs
The SEPARATOR regexp defaults to \"\\s-+\"."
  (let ((sep (or separator "\\s-+"))
	(i (string-match "[\"]" string)))
    (if (null i)
	(split-string string sep t)	; no quoting:  easy
      (append (unless (eq i 0) (split-string (substring string 0 i) sep t))
	      (let ((rfs (read-from-string string i)))
		(cons (car rfs)
		      (split-string-and-unquote (substring string (cdr rfs))
						sep)))))))
)

;;;###autoload
(defun kshdb (command-line)
  "Run kshdb on program FILE in buffer *kshdb-cmd-FILE*.
The directory containing FILE becomes the initial working directory
and source-file directory for your debugger.

You can specify a target script and its arguments like:

  bash YOUR-SCRIPT ARGUMENT...

or
  
  kshdb YOUR-SCRIPT ARGUMENT...

Generally the former one works fine. The later one may be useful if
you have not installed kshdb yet or you have installed kshdb to the
place where Bash doesn't expect

The custom variable `gud-kshdb-command-name' sets the pattern used
to invoke kshdb.

If `kshdb-many-windows' is nil (the default value) then kshdb just
starts with two windows: one displaying the GUD buffer and the
other with the source file with the main routine of the inferior.

If `kshdb-many-windows' is t, regardless of the value of the layout
below will appear.

+----------------------------------------------------------------------+
|                               GDB Toolbar                            |
+-----------------------------------+----------------------------------+
| GUD buffer (I/O of GDB)                                              |
|                                                                      |
|                                                                      |
|                                                                      |
+-----------------------------------+----------------------------------+
| Source buffer                                                        |
|                                                                      |
+-----------------------------------+----------------------------------+
| Stack buffer                      | Breakpoints buffer               |
| RET  kshdb-goto-stack-frame      | SPC kshdb-toggle-breakpoint     |
|                                   | RET kshdb-goto-breakpoint       |
|                                   | D   kshdb-delete-breakpoint     |
+-----------------------------------+----------------------------------+
."

  (interactive
   (list (read-from-minibuffer "Run kshdb (like this): "
			       (if (consp gud-kshdb-history)
				   (car gud-kshdb-history)
				 (concat gud-kshdb-command-name
					 " "))
			       gud-minibuffer-local-map nil
			       '(gud-kshdb-history . 1))))

  ; Parse the command line and pick out the script name and whether --annotate
  ; has been set.
  (let* ((words (split-string-and-unquote command-line))
	(script-name-annotate-p (kshdb-get-script-name 
			       (gud-kshdb-massage-args "1" words) nil))
	(target-name (file-name-nondirectory (car script-name-annotate-p)))
	(annotate-p (cadr script-name-annotate-p))
	(kshdb-buffer-name (format "*kshdb-cmd-%s*" target-name))
	(kshdb-buffer (get-buffer kshdb-buffer-name))
	)

    ;; `gud-kshdb-massage-args' needs whole `command-line'.
    ;; command-line is refered through dyanmic scope.
    (gud-common-init command-line 
		     (lambda (file args)
		       (gud-kshdb-massage-args file args command-line))
		     'gud-kshdb-marker-filter 'gud-kshdb-find-file)

    (setq gud-target-name target-name)
    ; gud-common-init sets the kshdb process buffer name incorrectly, because
    ; it can't parse the command line properly to pick out the script name.
    ; So we'll do it here and rename that buffer. The buffer we want to rename
    ; happens to be the current buffer.
    (when kshdb-buffer (kill-buffer kshdb-buffer))
    (rename-buffer kshdb-buffer-name)
    (setq comint-prompt-regexp "^kshdb<+(*[0-9]*)*>+ ")
    (setq paragraph-start comint-prompt-regexp)
    (set (make-local-variable 'gud-minor-mode) 'kshdb)
    (when (and annotate-p kshdb-many-windows) 
      (kshdb-setup-windows))

    (gud-def gud-args   "info args"     "a"
	     "Show arguments of the current stack frame.")
    (gud-def gud-break  "break %d%f:%l" "\C-b"
	     "Set breakpoint at the current line.")
    (gud-def gud-cont   "continue"   "\C-r" 
	     "Continue with display.")
    (gud-def gud-down   "down %p"     ">"
	     "Down N stack frames (numeric arg).")
    (gud-def gud-finish "finish"      "f\C-f"
	     "Finish executing current function.")
    (gud-def gud-linetrace "toggle"    "t"
	     "Toggle line tracing.")
    (gud-def gud-next   "next %p"     "\C-n"
	     "Step one line (skip functions).")
    (gud-def gud-print  "p %e"        "\C-p"
	     "Evaluate bash expression at point.")
    (gud-def gud-remove "clear %d%f:%l" "\C-d"
	     "Remove breakpoint at current line")
    (gud-def gud-run    "run"       "R"
	     "Restart the Bash script.")
    (gud-def gud-statement "eval %e" "\C-e"
	     "Execute Bash statement at point.")
    (gud-def gud-step   "step %p"       "\C-s"
	     "Step one source line with display.")
    (gud-def gud-tbreak "tbreak %d%f:%l"  "\C-t"
	     "Set temporary breakpoint at current line.")
    (gud-def gud-up     "up %p"
	     "<" "Up N stack frames (numeric arg).")
    (gud-def gud-where   "where"
	     "T" "Show stack trace.")
    
    ;; Update GUD menu bar
    (define-key gud-menu-map [args]      '("Show arguments of current stack" . 
					   gud-args))
    (define-key gud-menu-map [down]      '("Down Stack" . gud-down))
    (define-key gud-menu-map [eval]      '("Execute Bash statement at point" 
					   . gud-statement))
    (define-key gud-menu-map [finish]    '("Finish Function" . gud-finish))
    (define-key gud-menu-map [linetrace] '("Toggle line tracing" . 
					   gud-linetrace))
    (define-key gud-menu-map [run]       '("Restart the Bash Script" . 
					   gud-run))
    (define-key gud-menu-map [stepi]     nil)
    (define-key gud-menu-map [tbreak]    nil)
    (define-key gud-menu-map [up]        '("Up Stack" . gud-up))
    (define-key gud-menu-map [where]     '("Show stack trace" . gud-where))
    
    (local-set-key "\C-i" 'gud-bash-complete-command)
    
    (local-set-key [menu-bar debug tbreak] 
		   '("Temporary Breakpoint" . gud-tbreak))
    (local-set-key [menu-bar debug finish] '("Finish Function" . gud-finish))
    (local-set-key [menu-bar debug up] '("Up Stack" . gud-up))
    (local-set-key [menu-bar debug down] '("Down Stack" . gud-down))
    
    (run-hooks 'kshdb-mode-hook)
    ))
  
(defun gud-kshdb-complete-command (&optional command a b)
  "A wrapper for `gud-gdb-complete-command'"
  (gud-gdb-complete-command command a b))

(require 'comint)
(require 'custom)
(require 'cl)
(require 'compile)
(require 'shell)

(defun kshdb-setup-windows ()
  "Layout the window pattern for `kshdb-many-windows'. This was
mostly copied from `gdb-setup-windows', but simplified."
  (pop-to-buffer gud-comint-buffer)
  (let ((script-name gud-target-name))
    (delete-other-windows)
    (split-window nil ( / ( * (window-height) 3) 4))
    (split-window nil ( / (window-height) 3))
    ;(split-window-horizontally)
    ;(other-window 1)
    ; (set-window-buffer (selected-window) (get-buffer-create "*kshdb-locals*"))
    (other-window 1)
    (switch-to-buffer
     (if gud-last-last-frame
	 (gud-find-file (car gud-last-last-frame))
       ;; Put buffer list in window if we
       ;; can't find a source file.
       (list-buffers-noselect)))
    (other-window 1)
    (set-window-buffer 
     (selected-window) 
     (get-buffer-create (format "*kshdb-stack-%s*" script-name))
     (set (make-local-variable 'gud-target-name) script-name))
    (split-window-horizontally)
    (other-window 1)
    (set-window-buffer 
     (selected-window) 
     (get-buffer-create (format "*kshdb-breakpoints-%s*" script-name))
     (set (make-local-variable 'gud-target-name) script-name))
    (other-window 1)
    (goto-char (point-max))))

(defun kshdb-restore-windows ()
  "Equivalent of `gdb-restore-windows' for kshdb."
  (interactive)
  (when kshdb-many-windows
    (kshdb-setup-windows)))

(defun kshdb-set-windows (&optional name)
  "Sets window used in multi-window frame and issues
kshdb-restore-windows if kshdb-many-windows is set"
  (interactive "sProgram name: ")
  (when name (setq gud-target-name name)
	(setq gud-comint-buffer (current-buffer)))
  (when gud-last-frame (setq gud-last-last-frame gud-last-frame))
  (when kshdb-many-windows
    (kshdb-setup-windows)))

;; ALB fontification and keymaps for secondary buffers (breakpoints, stack)

;; -- breakpoints

(defvar kshdb-breakpoints-mode-map
  (let ((map (make-sparse-keymap))
	(menu (make-sparse-keymap "Breakpoints")))
    (define-key menu [quit] '("Quit"   . kshdb-delete-frame-or-window))
    (define-key menu [goto] '("Goto"   . kshdb-goto-breakpoint))
    (define-key menu [delete] '("Delete" . basdhb-delete-breakpoint))
    (define-key map [mouse-2] 'kshdb-goto-breakpoint-mouse)
    (define-key map [? ] 'kshdb-toggle-breakpoint)
    (define-key map [(control m)] 'kshdb-goto-breakpoint)
    (define-key map [?d] 'kshdb-delete-breakpoint)
    map)
  "Keymap to navigate/set/enable kshdb breakpoints.")

(defun kshdb-delete-frame-or-window ()
  "Delete frame if there is only one window.  Otherwise delete the window."
  (interactive)
  (if (one-window-p) (delete-frame)
    (delete-window)))

(defun kshdb-breakpoints-mode ()
  "Major mode for rdebug breakpoints.

\\{rdebug-breakpoints-mode-map}"
  (kill-all-local-variables)
  (setq major-mode 'kshdb-breakpoints-mode)
  (setq mode-name "KSHDB Breakpoints")
  (use-local-map kshdb-breakpoints-mode-map)
  (setq buffer-read-only t)
  (run-mode-hooks 'kshdb-breakpoints-mode-hook)
  ;(if (eq (buffer-local-value 'gud-minor-mode gud-comint-buffer) 'gdba)
  ;    'gdb-invalidate-breakpoints
  ;  'gdbmi-invalidate-breakpoints)
)

(defconst kshdb--breakpoint-regexp
  "^\\([0-9]+\\) +breakpoint +\\([a-z]+\\) +\\([a-z]+\\) +\\(.+\\):\\([0-9]+\\)$"
  "Regexp to recognize breakpoint lines in kshdb breakpoints buffers.")

(defun kshdb--setup-breakpoints-buffer (buf)
  "Detects breakpoint lines and sets up mouse navigation."
  (with-current-buffer buf
    (let ((inhibit-read-only t))
      (kshdb-breakpoints-mode)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((b (point-at-bol)) (e (point-at-eol)))
          (when (string-match kshdb--breakpoint-regexp
                              (buffer-substring b e))
            (add-text-properties b e
                                 (list 'mouse-face 'highlight
                                       'keymap kshdb-breakpoints-mode-map))
            (add-text-properties
             (+ b (match-beginning 1)) (+ b (match-end 1))
             (list 'face font-lock-constant-face
                   'font-lock-face font-lock-constant-face))
            (add-text-properties
             (+ b (match-beginning 3)) (+ b (match-end 3))
             (list 'face font-lock-constant-face
                   'font-lock-face font-lock-constant-face))
            ;; fontify "keep/del"
            (let ((face (if (string= "keep" (buffer-substring
                                             (+ b (match-beginning 2))
                                             (+ b (match-end 2))))
                            compilation-info-face
                          compilation-warning-face)))
              (add-text-properties
               (+ b (match-beginning 2)) (+ b (match-end 2))
               (list 'face face 'font-lock-face face)))
            ;; fontify "enabled"
            (when (string= "y" (buffer-substring (+ b (match-beginning 3))
                                                 (+ b (match-end 3))))
              (add-text-properties
               (+ b (match-beginning 3)) (+ b (match-end 3))
               (list 'face compilation-error-face
                     'font-lock-face compilation-error-face)))
            (add-text-properties
             (+ b (match-beginning 4)) (+ b (match-end 4))
             (list 'face font-lock-comment-face
                   'font-lock-face font-lock-comment-face))
            (add-text-properties
             (+ b (match-beginning 5)) (+ b (match-end 5))
             (list 'face font-lock-constant-face
                   'font-lock-face font-lock-constant-face)))
        (forward-line)
        (beginning-of-line))))))

(defun kshdb-goto-breakpoint-mouse (event)
  "Displays the location in a source file of the selected breakpoint."
  (interactive "e")
  (with-current-buffer (window-buffer (posn-window (event-end event)))
    (kshdb-goto-breakpoint (posn-point (event-end event)))))

(defun kshdb-goto-breakpoint (pt)
  "Displays the location in a source file of the selected breakpoint."
  (interactive "d")
  (save-excursion
    (goto-char pt)
    (let ((s (buffer-substring (point-at-bol) (point-at-eol))))
      (when (string-match kshdb--breakpoint-regexp s)
        (kshdb-display-line
         (substring s (match-beginning 4) (match-end 4))
         (string-to-number (substring s (match-beginning 5) (match-end 5))))
        ))))

(defun kshdb-goto-trace-line ()
  "Displays the location in a source file of a trace line."
  (interactive "")
  (save-excursion
    (goto-char (point))
    (let ((s (buffer-substring (line-beginning-position) (line-end-position)))
	  (gud-comint-buffer (current-buffer)))
      (when (string-match kshdb-position-re s)
        (kshdb-display-line
         (substring s (match-beginning 2) (match-end 2))
         (string-to-number (substring s (match-beginning 3) (match-end 3))))
        ))))

(defun kshdb-toggle-breakpoint (pt)
  "Toggles the breakpoint at PT in the breakpoints buffer."
  (interactive "d")
  (save-excursion
    (goto-char pt)
    (let ((s (buffer-substring (point-at-bol) (point-at-eol))))
      (when (string-match kshdb--breakpoint-regexp s)
        (let* ((enabled
                (string= (substring s (match-beginning 3) (match-end 3)) "y"))
               (cmd (if enabled "disable" "enable"))
               (bpnum (substring s (match-beginning 1) (match-end 1))))
          (gud-call (format "%s %s" cmd bpnum)))))))

(defun kshdb-delete-breakpoint (pt)
  "Deletes the breakpoint at PT in the breakpoints buffer."
  (interactive "d")
  (save-excursion
    (goto-char pt)
    (let ((s (buffer-substring (point-at-bol) (point-at-eol))))
      (when (string-match kshdb--breakpoint-regexp s)
        (let ((bpnum (substring s (match-beginning 1) (match-end 1))))
          (gud-call (format "delete %s" bpnum)))))))

(defun kshdb-display-line (file line &optional move-arrow)
  (let ((oldpos (and gud-overlay-arrow-position
                     (marker-position gud-overlay-arrow-position)))
        (oldbuf (and gud-overlay-arrow-position
                     (marker-buffer gud-overlay-arrow-position))))
    (gud-display-line file line)
    (unless move-arrow
      (when gud-overlay-arrow-position
        (set-marker gud-overlay-arrow-position oldpos oldbuf)))))


;; -- stack

(defvar kshdb--stack-frame-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] 'kshdb-goto-stack-frame-mouse)
    (define-key map [mouse-2] 'kshdb-goto-stack-frame-mouse)
    (define-key map [(control m)] 'kshdb-goto-stack-frame)
    map)
  "Keymap to navigate kshdb stack frames.")

(defconst kshdb--stack-frame-regexp
  "^\\(->\\|##\\| +\\)+\\([0-9]+\\) \\(.*\\) file `\\([^']+\\)' at line \\([0-9]+\\)$"
  "Regexp to recognize stack frame lines in kshdb stack buffers.")

(defun kshdb--setup-stack-buffer (buf)
  "Detects stack frame lines and sets up mouse navigation."
  (with-current-buffer buf
    (let ((inhibit-read-only t)
	  (current-frame-point nil) ; position in stack buffer of selected frame
	  )
      (setq mode-name "KSHDB Stack Frames")
      (goto-char (point-min))
      
      (while (not (eobp))
        (let* ((b (point-at-bol)) 
	       (e (point-at-eol))
               (s (buffer-substring b e))
	       )
          (when (string-match kshdb--stack-frame-regexp s)
            (add-text-properties
             (+ b (match-beginning 2)) (+ b (match-end 2))
             (list 'face font-lock-constant-face
                   'font-lock-face font-lock-constant-face))
            (add-text-properties
             (+ b (match-beginning 4)) (+ b (match-end 4))
             (list 'face font-lock-comment-face
                   'font-lock-face font-lock-comment-face))
            (add-text-properties
             (+ b (match-beginning 5)) (+ b (match-end 5))
             (list 'face font-lock-constant-face
                   'font-lock-face font-lock-constant-face))
             (list 'face font-lock-function-name-face
                   'font-lock-face font-lock-function-name-face))
            (when (string= (substring s (match-beginning 1) (match-end 1)) "->")
                ;; highlight the currently selected frame
	      (add-text-properties b e
				   (list 'face 'bold
					 'font-lock-face 'bold))
	      (setq overlay-arrow-position (make-marker))
	      (set-marker overlay-arrow-position (point))
	      (setq current-frame-point (point)))
            (add-text-properties b e
                                 (list 'mouse-face 'highlight
                                       'keymap kshdb--stack-frame-map))
	    (let ((fn-str (substring s (match-beginning 3) (match-end 3)))
		  (fn-start (+ b (match-beginning 3))))
	      (if (string-match "\\([^(]+\\)(" fn-str)
		  (add-text-properties
		   (+ fn-start (match-beginning 1)) (+ fn-start (match-end 1))
		   (list 'face font-lock-function-name-face
			 'font-lock-face font-lock-function-name-face)))
	      (add-text-properties b e
				   (list 'mouse-face 'highlight
					 'keymap kshdb--stack-frame-map))))
	;; remove initial ##  or ->
	(beginning-of-line)
	(delete-char 2)
        (forward-line)
        (beginning-of-line))
      ; Go back to the selected frame if any
      (when current-frame-point (goto-char current-frame-point))
      )))

(defun kshdb-goto-stack-frame (pt)
  "Show the kshdb stack frame correspoding at PT in the kshdb stack buffer."
  (interactive "d")
  (save-excursion
    (goto-char pt)
    (let ((s (concat "##" (buffer-substring (point-at-bol) (point-at-eol)))))
      (when (string-match kshdb--stack-frame-regexp s)
        (let ((frame (substring s (match-beginning 2) (match-end 2))))
          (gud-call (concat "frame " frame)))))))

(defun kshdb-goto-stack-frame-mouse (event)
  "Show the kshdb stack frame under the mouse in the kshdb stack buffer."
  (interactive "e")
  (with-current-buffer (window-buffer (posn-window (event-end event)))
    (kshdb-goto-stack-frame (posn-point (event-end event)))))

;; -- locals

(defun kshdb--setup-locals-buffer (buf)
  (with-current-buffer buf
    (setq mode-name "KSHDB Locals")))

(defadvice gud-reset (before kshdb-reset)
  "kshdb cleanup - remove debugger's internal buffers (frame, breakpoints, 
etc.)."
  (dolist (buffer (buffer-list))
    (when (string-match "\\*kshdb-[a-z]+\\*" (buffer-name buffer))
      (let ((w (get-buffer-window buffer)))
        (when w (delete-window w)))
      (kill-buffer buffer))))

(ad-activate 'gud-reset)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; kshdbtrack --- tracking kshdb debugger in an Emacs shell window
;;; Modified from  python-mode in particular the part:
;; pdbtrack support contributed by Ken Manheimer, April 2001.

;;; Code:

(defun kshdbtrack-overlay-arrow (activation)
  "Activate or de arrow at beginning-of-line in current buffer."
  ;; This was derived/simplified from edebug-overlay-arrow
  (cond (activation
	 (setq overlay-arrow-position (make-marker))
	 (setq overlay-arrow-string "=>")
	 (set-marker overlay-arrow-position (point) (current-buffer))
	 (setq kshdbtrack-is-tracking-p t))
	(kshdbtrack-is-tracking-p
	 (setq overlay-arrow-position nil)
	 (setq kshdbtrack-is-tracking-p nil))
	))

(defun kshdbtrack-track-stack-file (text)
  "Show the file indicated by the kshdb stack entry line, in a separate window.
Activity is disabled if the buffer-local variable
`kshdbtrack-do-tracking-p' is nil.

We depend on the kshdb input prompt matching `kshdbtrack-input-prompt'
at the beginning of the line.
" 
  ;; Instead of trying to piece things together from partial text
  ;; (which can be almost useless depending on Emacs version), we
  ;; monitor to the point where we have the next kshdb prompt, and then
  ;; check all text from comint-last-input-end to process-mark.
  ;;
  ;; Also, we're very conservative about clearing the overlay arrow,
  ;; to minimize residue.  This means, for instance, that executing
  ;; other kshdb commands wipe out the highlight.  You can always do a
  ;; 'where' (aka 'w') command to reveal the overlay arrow.
  (let* ((origbuf (current-buffer))
	 (currproc (get-buffer-process origbuf)))

    (if (not (and currproc kshdbtrack-do-tracking-p))
        (kshdbtrack-overlay-arrow nil)
      ;else 
      (let* ((procmark (process-mark currproc))
	     (block-start (max comint-last-input-end
			       (- procmark kshdbtrack-track-range)))
             (block-str (buffer-substring block-start procmark))
             target target_fname target_lineno target_buffer)

        (if (not (string-match (concat kshdbtrack-input-prompt "$") block-str))
            (kshdbtrack-overlay-arrow nil)

          (setq target (kshdbtrack-get-source-buffer block-str))

          (if (stringp target)
              (message "kshdbtrack: %s" target)
	    ;else
	    (gud-kshdb-marker-filter block-str)
            (setq target_lineno (car target))
            (setq target_buffer (cadr target))
            (setq target_fname (buffer-file-name target_buffer))
            (switch-to-buffer-other-window target_buffer)
            (goto-line target_lineno)
            (message "kshdbtrack: line %s, file %s" target_lineno target_fname)
            (kshdbtrack-overlay-arrow t)
            (pop-to-buffer origbuf t)
	    )

	  ; Delete processed annotations from buffer.
	  (save-excursion
	    (let ((annotate-start)
		  (annotate-end (point-max)))
	      (goto-char block-start)
	      (while (re-search-forward
		      kshdb-annotation-start-regexp annotate-end t)
		(setq annotate-start (match-beginning 0))
		(if (re-search-forward 
		     kshdb-annotation-end-regexp annotate-end t)
		    (delete-region annotate-start (point))
		;else
		  (forward-line)))
	      )))
	)))
  )

(defun kshdbtrack-get-source-buffer (block)
  "Return line number and buffer of code indicated by block's traceback text.

We look first to visit the file indicated in the trace.

Failing that, we look for the most recently visited python-mode buffer
with the same name or having 
having the named function.

If we're unable find the source code we return a string describing the
problem as best as we can determine."

  (if (not (string-match kshdb-position-re block))

      "line number cue not found"

    (let* ((filename (match-string kshdb-marker-regexp-file-group block))
           (lineno (string-to-number
		    (match-string kshdb-marker-regexp-line-group block)))
           funcbuffer)

      (cond ((file-exists-p filename)
             (list lineno (find-file-noselect filename)))

            ((= (elt filename 0) ?\<)
             (format "(Non-file source: '%s')" filename))

            (t (format "Not found: %s" filename)))
      )
    )
  )


;;; Subprocess commands



;; kshdbtrack functions
(define-minor-mode kshdbtrack-mode ()
  "Minor mode for tracking bash debugging inside a process shell."
  :init-value nil
  ;; The indicator for the mode line.
  :lighter kshdbtrack-minor-mode-text
  ;; The minor mode bindings.
  :global nil
  :group 'kshdb
  (kshdbtrack-toggle-stack-tracking 1)
  (setq kshdbtrack-is-tracking-p t)
  (local-set-key "\C-cg" 'kshdb-goto-trace-line)
  (add-hook 'comint-output-filter-functions 'kshdbtrack-track-stack-file)
  (run-mode-hooks 'kshdbtrack-mode-hook))

(defun kshdbtrack-toggle-stack-tracking (arg)
  (interactive "P")
  (if (not (get-buffer-process (current-buffer)))
      (error "No process associated with buffer '%s'" (current-buffer)))
  ;; missing or 0 is toggle, >0 turn on, <0 turn off
  (if (or (not arg)
	  (zerop (setq arg (prefix-numeric-value arg))))
      (setq kshdbtrack-do-tracking-p (not kshdbtrack-do-tracking-p))
    (setq kshdbtrack-do-tracking-p (> arg 0)))
  (message "%sabled kshdb's kshdbtrack"
           (if kshdbtrack-do-tracking-p "En" "Dis")))

(defun turn-on-kshdbtrack ()
  "Turn on kshdbtrack mode.

This function is designed to be added to hooks, for example:
  (add-hook 'comint-mode-hook 'turn-on-kshdbtrack-mode)"
  (interactive)
  (kshdbtrack-mode 1)
)

(defun turn-off-kshdbtrack ()
  (interactive)
  (remove-hook 'comint-output-filter-functions 
	       'kshdbtrack-track-stack-file)
  (setq kshdbtrack-is-tracking-p nil)
  (kshdbtrack-toggle-stack-tracking 0))

;; Add a designator to the minor mode strings
(or (assq 'kshdb-kshdbtrack-is-tracking-p minor-mode-alist)
    (push '(kshdb-kshdbtrack-is-tracking-p
	    kshdb-kshdbtrack-minor-mode-string)
	  minor-mode-alist))

;;; kshdbtrack.el ends here

(provide 'kshdb)
;;; kshdb.el ends here
