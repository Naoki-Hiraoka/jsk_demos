#!/usr/bin/env roseus

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "hiraoka_semi")
(ros::load-ros-manifest "dynamic_reconfigure")
(load "package://hiraoka_semi/euslisp/init.l")
(ros::roseus "main")

(setq photo-num 0);写真を撮った回数

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

;;写真を撮る
(call-empty-service "/my_image_saver/save" :wait t)
(setq photo-num-before photo-num)
(incf photo-num)
(ros::ros-info "photo before was taken")

;;ココで手動でポスターを一個追加する
(unix::sleep 20)

;;写真を送信
(setq file_name (ros::get-param "~file_name"))
(setq format_name (ros::get-param "~format_name"))

;;前の画像を送信する
(ros::wait-for-service "/image_publisher/set_parameters")
(setq dynamic_msg (instance dynamic_reconfigure::ReconfigureRequest :init))
(send dynamic_msg :config :strs (list (instance dynamic_reconfigure::StrParameter :init :name "file_name" :value (concatenate string file_name (string photo-num-before) format_name))))
(ros::service-call "/image_publisher/set_parameters" dynamic_msg)
(setq time-target (ros::time-now))
(setq time-now (instance ros::time :init))
(ros::subscribe "/hsv_decomposer/output/hue" sensor_msgs::image #'(lambda (msg) (setq time-now (send msg :header :stamp))))
(ros::rate 10)
(ros::ros-info "photo before was send")
(while (ros::time< time-now time-target)
  (ros::spin-once)
  (ros::sleep)
  )
(ros::unsubscribe "/hsv_decomposer/output/hue") 

;;写真を撮る
(call-empty-service "/my_image_saver/save" :wait t)
(setq photo-num-after photo-num)
(incf photo-num)
(ros::ros-info "photo after was taken")

;;2つの写真の差分を計算する
;;今の画像からの差分を計算せよと命令
(ros::subscribe "/image_time_diff/output/diff_image" sensor_msgs::image #'(lambda (msg) (setq time-now (send msg :header :stamp))))
(ros::ros-info "start diff detection")

(ros::advertise "/image_time_diff/start" std_msgs::Header 1)
(setq msg (instance std_msgs::Header :init))
(send msg :stamp (ros::time-now))

(while (zerop (ros::get-num-subscribers "/image_time_diff/start"))
    (ros::sleep))

(ros::publish "/image_time_diff/start" msg)
(setq time-target (ros::time-now))
(while (ros::time< time-now time-target)
  (ros::spin-once)
  ;;(ros::publish "/image_time_diff/start" msg);;最初の一回だと反応しないみたい
  (ros::sleep)
  )
(ros::unsubscribe "/image_time_diff/output/diff_image")

;;保存完了するまで時間を稼ぐ
(unix::sleep 5)

;;後の画像を送信する
(send dynamic_msg :config :strs (list (instance dynamic_reconfigure::StrParameter :init :name "file_name" :value (concatenate string file_name (string photo-num-after) format_name))))
(ros::service-call "/image_publisher/set_parameters" dynamic_msg)
(setq time-target (ros::time-now))
(send time-target :sec (+ (send time-target :sec) 1))
(ros::ros-info "photo after was send")

;;差分の位置を受信する
(setq polygon (instance geometry_msgs::PolygonStamped :init))
(ros::subscribe "/mask_image_to_rect/output" geometry_msgs::PolygonStamped #'(lambda (msg) (setq polygon msg) (setq time-now (send msg :header :stamp))))
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
(setq req (instance hiraoka_semi::image_parts_saverRequest :init))
(send req :file_name (concatenate string file_name (string photo-num-after)))
(send req :format_name format_name)
(send req :parts (list change))
(ros::service-call "image_parts_saver" req)

;;帰ってくる
;; (send *pr2* :move-to (send (send *scene* :spot "init-spot") :worldcoords) :world)
;; (send *irtviewer* :look-all *pr2*)
;; (x::window-main-one)
;; (send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")

(do-until-key
 (ros::sleep))

(exit)
