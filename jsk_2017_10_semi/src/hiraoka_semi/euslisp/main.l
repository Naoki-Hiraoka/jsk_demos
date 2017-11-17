#!/usr/bin/env roseus

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "hiraoka_semi")
(ros::load-ros-manifest "dynamic_reconfigure")
(load "package://hiraoka_semi/euslisp/init.l")
(ros::roseus "main")

(setq photo-num 0);写真を撮った回数

;;掲示板の前まで移動
(send *pr2* :move-to (send (send *scene* :spot "/eng2/7f/before-elevator") :worldcoords) :world)
(send *irtviewer* :look-all *pr2*)
(x::window-main-one)
(send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")
(send *pr2* :move-to (make-coords :pos (send *pr2* :worldpos) :rpy (float-vector pi/2 0 0)) :world)
(send *irtviewer* :look-all *pr2*)
(x::window-main-one)
(send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")

;;ココでカメラが昨日と同じ位置に来るようにうまく調整したい

;;写真を撮る
(call-empty-service "/my_image_saver/save" :wait t)
(setq photo-num-before photo-num)
(incf photo-num)

;;ココで手動でポスターを一個追加する
(unix::sleep 10)

;;写真を撮る
(call-empty-service "/my_image_saver/save" :wait t)
(setq photo-num-after photo-num)
(incf photo-num)

;;保存完了するまで時間を稼ぐ
(unix::sleep 10)

;;2つの写真の差分を計算する
(setq file_name (ros::get-param "~file_name"))
(setq format_name (ros::get-param "~format_name"))
;; (setq req (instance hiraoka_semi::change_of_notice_boardRequest :init))
;; (send req :before (concatenate string file_name (string photo-num-before) format_name))
;; (send req :after (concatenate string file_name (string photo-num-after) format_name))
;; (setq res (ros::service-call "change_of_notice_board" req))
;前の画像を送信する
(ros::wait-for-service "/image_publisher/set_parameters")
(setq dynamic_msg (instance dynamic_reconfigure::ReconfigureRequest :init))
(send dynamic_msg :config :strs (list (instance dynamic_reconfigure::StrParameter :init :name "file_name" :value (concatenate string file_name (string photo-num-before) format_name))))
(ros::service-call "/image_publisher/set_parameters" dynamic_msg)
;;今の画像からの差分を計算せよと命令
(ros::advertise "/image_time_diff/start" std_msgs::Header 1)
(setq msg (instance std_msgs::Header :init))
(send msg :stamp (ros::time-now))
(ros::publish "/image_time_diff/start" msg)
;;後の画像を送信する
(send dynamic_msg :config :strs (list (instance dynamic_reconfigure::StrParameter :init :name "file_name" :value (concatenate string file_name (string photo-num-after) format_name))))
(ros::service-call "/image_publisher/set_parameters" dynamic_msg)

(setq newpaper (instance opencv_apps::RotatedRect :init)) 
(defun rect_image-cb (msg)
;;ここから  (send newpaper :cenner :x 
(ros::subscribe "/mask_image_to_rect/output" geometry_msgs/PolygonStamped #')

;;差分を保存する(要編集)
;;ターゲットの位置まで近づいて、新たに写真を撮ってとできればいいなあ
(setq req (instance hiraoka_semi::image_parts_saverRequest :init))
(send req :file_name file_name)
(send req :format_name format_name)
(send req :parts (send res :changes))
(ros::service-call "image_parts_saver" req)

;;帰ってくる
(send *pr2* :init-pose)
(send *pr2* :move-to (send (send *scene* :spot "init-spot") :worldcoords) :world)
(send *irtviewer* :look-all *pr2*)
(x::window-main-one)
(send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
(send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")

