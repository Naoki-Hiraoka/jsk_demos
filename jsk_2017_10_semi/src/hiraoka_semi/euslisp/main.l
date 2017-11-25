#!/usr/bin/env roseus

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "hiraoka_semi")
(ros::load-ros-manifest "dynamic_reconfigure")
;;(load "package://hiraoka_semi/euslisp/init.l")
(ros::roseus "main")

;; ;;掲示板の前まで移動

;; (send *pr2* :move-to (send (send *scene* :spot "/eng2/7f/before-elevator") :worldcoords) :world)
;; (send *irtviewer* :look-all *pr2*)
;; (x::window-main-one)
;; (send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")
;; (send *pr2* :move-to (make-coords :pos (send *pr2* :worldpos) :rpy (float-vector pi/2 0 0)) :world)
;; (send *irtviewer* :look-all *pr2*)
;; (x::window-main-one)
;; (send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")


;;ココでカメラが昨日と同じ位置に来るようにうまく調整したい

;;動画を撮る
(setq file_name (ros::get-param "~file_name"))
(setq topic_name (ros::get-param "~topic_name"))
(setq req (instance hiraoka_semi::video_recorderrequest :init))
(send req :filename file_name)
(send req :topicname topic_name)
(send req :start t)
(ros::ros-info "video start")
(ros::wait-for-service "/video_recorder")
(ros::service-call "/video_recorder" req)
(unix::sleep 10)
(send req :start nil)
(send req :stop t)
(ros::ros-info "video stop")
(ros::service-call "/video_recorder" req)

;;ココで手動でポスターを一個追加する
(ros::ros-info "waiting")
(unix::sleep 10)

;;差分を取らせる
(setq req (instance dynamic_reconfigure::Reconfigurerequest :init))
(send req :config :strs (list (instance dynamic_reconfigure::StrParameter :init :name "filename" :value file_name) (instance dynamic_reconfigure::StrParameter :init :name "topicname" :value topic_name)))   
(ros::wait-for-service "/background_subtractor/set_parameters")
(ros::service-call "/background_subtractor/set_parameters" req)

;;差分の位置を受信する
(setq polygon (instance geometry_msgs::PolygonStamped :init))
(ros::subscribe "/mask_image_to_rect/output" geometry_msgs::PolygonStamped #'(lambda (msg) (setq polygon msg) (setq time-now (send msg :header :stamp))))
(setq time-target (ros::time-now))
(setq time-now (instance ros::time :init))
(while (ros::time< time-now time-target)
  (ros::spin-once)
  (ros::sleep)
  )
(ros::ros-info "diff was received")
(ros::unsubscribe "/mask_image_to_rect/output") 

;;rotated-rectに変換
(setq pointul (car (send polygon :polygon :points)))
(setq pointdr (cadr (send polygon :polygon :points)))
(setq change (instance opencv_apps::rotatedrect :init))
(send change :angle 0.0)
(send change :center :x (/ (+ (send pointul :x) (send pointdr :x)) 2.0))
(send change :center :y (/ (+ (send pointul :y) (send pointdr :y)) 2.0))
(send change :size :width (- (send pointdr :x) (send pointul :x)))
(send change :size :height (- (send pointdr :y) (send pointul :y)))

;;差分を保存する
;;ターゲットの位置まで近づいて、新たに写真を撮ってとできればいいなあ
(setq req (instance hiraoka_semi::image_part_saverRequest :init))
(setq file_name (ros::get-param "~save_name"))
(send req :file_name file_name)
(send req :parts (list change))
(ros::service-call "image_part_saver" req)

;;帰ってくる
;; (send *pr2* :move-to (send (send *scene* :spot "init-spot") :worldcoords) :world)
;; (send *irtviewer* :look-all *pr2*)
;; (x::window-main-one)
;; (send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")

(do-until-key
 (ros::sleep))

(exit)
