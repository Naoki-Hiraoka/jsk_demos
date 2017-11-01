;;rossetip 000.000.000.000
;;rossetmaster fetch15
;;(roscore)
;;roseus
(load "package://fetcheus/fetch-interface.l")
(fetch-init)

(load "package://jsk_maps/src/eng2-scene.l")
(setq *scene* (make-eng2-scene))
(objects (list *fetch* *scene*))
(send *irtviewer* :look-all *fetch*)
;;(send *fetch* :init-pose)
