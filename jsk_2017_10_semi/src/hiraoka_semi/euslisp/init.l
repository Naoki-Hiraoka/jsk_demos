;;rossetip 000.000.000.000
;;rossetmaster pr1012
;;//roscore
;;roseus
(load "package://pr2eus/pr2-interface.l")
(pr2-init)

(load "package://jsk_maps/src/eng2-scene.l")
(setq *scene* (make-eng2-scene))
;;掲示板を追加
(setq *panel* (make-cube 3000 100 1500 :name "/eng2/7f/notice-board"))
(send *panel* :move-to (make-coords :pos #F(2500 -26000 31000)) :world)
(send *panel* :set-color :green)

(objects (list *pr2* *scene* *panel*))
