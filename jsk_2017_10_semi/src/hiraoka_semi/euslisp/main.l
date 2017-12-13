#!/usr/bin/env roseus

(ros::load-ros-manifest "roseus")
;;(ros::roseus "main")
(load "package://pr2eus/pr2-interface.l")
(pr2-init)

(setq debug (ros::get-param "~debug"))

(ros::load-ros-manifest "hiraoka_semi")
(ros::load-ros-manifest "dynamic_reconfigure")
(unless debug (load "package://hiraoka_semi/euslisp/tweet_sender.l"))

(load "package://jsk_maps/src/eng2-scene.l")
(setq *scene* (make-eng2-scene))
;;掲示板を追加
(setq *panel* (make-cube 3000 100 1500 :name "/eng2/7f/notice-board"))
(send *panel* :move-to (make-coords :pos #F(2500 -26000 31000)) :world)
(send *panel* :set-color :green)
(objects (list *pr2* *scene* *panel*))

(unless debug
  (pr2-tuckarm-pose)
  (send *pr2* :move-to (send (send *scene* :spot "init-spot") :worldcoords) :world)
  (send *irtviewer* :look-all *pr2*)
  ;; (send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")

  ;; ;;掲示板の前まで移動
  ;; (send *pr2* :move-to (make-coords :pos #f(-1000 5000 30002)) :world)
  ;; ;;下の行は後でコメント解除すること
  ;; ;;(send *pr2* :move-to (send (send (send *scene* :spot "/eng2/7f/before-elevator") :copy-worldcoords) :orient pi/2 :z) :world)
  ;; (send *irtviewer* :look-all *pr2*)
  ;; (x::window-main-one)
  ;; (send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")
)

(ros::rate 10)

;;動画を撮る
(setq file_name (ros::get-param "~file_name"))
(setq topic_name (ros::get-param "~topic_name"))
(setq req (instance hiraoka_semi::video_recorderrequest :init))
(send req :filename file_name)
(send req :topicname topic_name)
(send req :start t)
(ros::ros-info "video start")
(ros::wait-for-service "/hiraoka_semi/video_recorder")
(ros::service-call "/hiraoka_semi/video_recorder" req)
(unix::sleep 20)
(send req :start nil)
(send req :stop t)
(ros::ros-info "video stop")
(ros::service-call "/hiraoka_semi/video_recorder" req)

;;ココで手動でポスターを一個追加する
(ros::ros-info "waiting")
(unix::sleep 10)

;;差分を取らせる
(setq req (instance dynamic_reconfigure::Reconfigurerequest :init))
(send req :config :strs (list (instance dynamic_reconfigure::StrParameter :init :name "filename" :value file_name) (instance dynamic_reconfigure::StrParameter :init :name "topicname" :value topic_name)))   
(ros::wait-for-service "/hiraoka_semi/background_subtractor/set_parameters")
(ros::service-call "/hiraoka_semi/background_subtractor/set_parameters" req)

;;差分の位置を受信する
(setq polygon (instance geometry_msgs::PolygonStamped :init))
(ros::subscribe "/hiraoka_semi/mask_image_to_rect/output" geometry_msgs::PolygonStamped #'(lambda (msg) (setq polygon msg) (setq time-now (send msg :header :stamp))))
(setq time-target (ros::time-now))
(send time-target :sec (+ (send time-target :sec) 3))
(setq time-now (instance ros::time :init))
(while (ros::time< time-now time-target)
  (ros::spin-once)
  (ros::sleep)
  )
(ros::ros-info "diff was received")
(ros::unsubscribe "/hiraoka_semi/mask_image_to_rect/output") 

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
(ros::service-call "/hiraoka_semi/image_part_saver" req)
(unix::sleep 5);;保存完了まで

;;画像を送信する
(setq dynamic_msg (instance dynamic_reconfigure::ReconfigureRequest :init))
(send dynamic_msg :config :strs (list (instance dynamic_reconfigure::StrParameter :init :name "file_name" :value file_name)))
(ros::service-call "/hiraoka_semi/change_image_publisher/set_parameters" dynamic_msg)
(setq time-target (ros::time-now))
(send time-target :sec (+ (send time-target :sec) 1))
(ros::ros-info "change image was published")  

;;twitterに送信
(unless debug
  (ros::subscribe "/hiraoka_semi/change_image_publisher/output" sensor_msgs::image #'(lambda (msg) (setq time-now (send msg :header :stamp))))
  (setq time-now (instance ros::time :init))
  (while (ros::time< time-now time-target)
  (ros::spin-once)
  (ros::sleep)
  )
  (ros::unsubscribe "/hiraoka_semi/change_image_publisher/output") 
  (tweet-string "hello,jsk" :with-image "/hiraoka_semi/change_image_publisher/output")
  )


;; (unless debug  
;;   ;;帰ってくる
;;   (send *pr2* :move-to (send (send *scene* :spot "init-spot") :worldcoords) :world)
;;   (send *irtviewer* :look-all *pr2*)
;;   (x::window-main-one)
;;   (send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")
;; )

(do-until-key
 (ros::sleep))

(exit)
