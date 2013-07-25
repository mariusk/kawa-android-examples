(module-name net.kjeldahl.kawaandroid.)
(require 'android-defs)
;;(define-simple-class MainActivity (android.app.Activity))
(activity MainActivity
  (on-create-view 
   (define counter ::integer 0)
   (define counter-view
     (TextView text: "Not clicked yet."))
   (LinearLayout orientation: LinearLayout:VERTICAL
    (TextView text: "Hello, Android from Kawa Scheme!")
    (Button
     text: "Click here!"
     on-click-listener: (lambda (e)
                          (set! counter (+ counter 1))
                          (counter-view:setText
                           (format "Clicked ~d times." counter))))
    counter-view)))
