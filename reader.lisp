;;A package for defining read table extensions 
;;for clojure data structures.  

;;Pending..................
(defpackage :clclojure.reader
  (:use :common-lisp :common-utils :named-readtables)
  (:export :nth-vec :*literals* :quoted-children :quote-sym :literal?))
(in-package :clclojure.reader)

(comment 
 (defconstant +left-bracket+ #\[)
 (defconstant +right-bracket+ #\])
 (defconstant +left-brace+ #\{)
 (defconstant +right-brace+ #\})
 (defconstant +comma+ #\,)
 (defconstant +colon+ #\:)


 (defconstant +at+ #\@)
 (defconstant +tilde+ #\~))

(EVAL-WHEN (:compile-toplevel :load-toplevel :execute)

  ;;Problem right now is that, when we read using delimited-list,
  ;;we end up losing out on the reader literal for pvecs and the like...
  ;;When we have quoted 
  
  ;;we can use a completely custom reader...perhaps that's easiet..
  ;;Have to make this available to the compiler at compile time!
  ;;Maybe move this into a clojure-readers.lisp or something.

  ;;alist of literals...
  (defparameter *literals*  '(list cons))
  ;;default quote...o
  ;; (comment 
  ;;  (set-macro-character #\'
  ;;                       #'(lambda (stream char)
  ;;                           (declare (ignore char))
  ;;                           `(quote ,(read stream t nil t)))))
  (defun    quote-sym (sym) (list 'quote sym)) ;`(quote ,sym)
  ;; (defmacro quoted-children (c)  
  ;;   `(,(first c)  ,@(mapcar #'quote-sym  (rest c))))

  (defun literal? (s) (or  (and (listp s)   (find (first s) *literals*))
                           (and (symbolp s) (find s *literals*))))
  (defmacro quoted-children (c)
    `(,(first c)
      ,@(mapcar (lambda (s)
                  (cond ((literal? s) ;;we need to recursively call quoted-children..
                         `(quoted-children ,s))
                        ((listp s)
                         `(quoted-children ,(cons  (quote list) s)))
                        (t (funcall #'quote-sym s))))  (rest c))))
  
  ;;Enforces quoting semantics for literal data structures..
  (defmacro clj-quote (expr)
    (cond ((literal? expr)  `(quoted-children ,expr))
          ((listp expr)
           `(quoted-children ,(cons  (quote list) expr)))
          (t
           (quote-sym expr))))
  
  (defun as-char (x)
    (cond ((characterp x) x)
          ((and (stringp x)
                (= 1 (length x))) (char x 0))
          ((symbolp x) (as-char (str x)))
          (t (error (str (list "invalid-char!" x) ))))
    )
  
  ;;Gives us clj->cl reader for chars...
  (set-macro-character #\\
     #'(lambda (stream char)
         (declare (ignore char))
         (let ((res (read stream t nil t)))
           (as-char res)))
     )

  ;;Doesn't work currently, since we can't redefine
  ;;print-method for chars...
  (defun print-clj-char (c &optional (stream t))
    "Generic char printer for clojure-style syntax."
    (format stream "\~c" c))

  (defun print-cl-char (c &optional (stream t))
    "Generic char printer for common lisp syntax."
    (format stream "#\~c" c))

  (comment  (defmethod print-object ((obj standard-char) stream)
              (print-clj-char obj stream)))
  
  ;;This should be consolidated...
  (set-macro-character #\'
     #'(lambda (stream char)
         (declare (ignore char))
         (let ((res (read stream t nil t)))
           (if (atom res)  `(quote ,res)
               `(clj-quote ,res)))))

  (defun push-reader! (literal ldelim rdelim rdr)
    (progn (setf  *literals* (union  (list literal) *literals*))
           (set-macro-character ldelim rdr)
           (set-syntax-from-char rdelim #\))))
  
  ;; (comment (defun |brace-reader| (stream char)
  ;;            "A reader macro that allows us to define persistent vectors
  ;;   inline, just like Clojure."
  ;;            (declare (ignore char))
  ;;            `(persistent-vector ,@(read-delimited-list #\] stream t)))
  ;;          (set-macro-character #\{ #'|brace-reader|)
  ;;          (set-syntax-from-char #\} #\))

  ;;          ;;standard quote dispatch
  ;;          (set-macro-character #\'  #'(lambda (stream char)
  ;;                                        (list 'quote (read stream t nil t))))
           
           
  ;;          (set-macro-character #\'  #'(lambda (stream char)
  ;;                                        (let ((res (read stream t nil t)))
  ;;                                          (case (first res)
  ;;                                            ('persistent-vector 'persistent- ))
  ;;                                          (list 'quote )))))
  


  ;;https://gist.github.com/chaitanyagupta/9324402
  ;;https://common-lisp.net/project/named-readtables/


  )
