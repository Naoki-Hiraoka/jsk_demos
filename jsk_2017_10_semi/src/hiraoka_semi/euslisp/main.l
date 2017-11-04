#!/usr/bin/env roseus

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "hiraoka_semi")
(load "package://hiraoka_semi/init.l")
(ros::roseus "main")

(setq photo-num 0);写真を撮った回数

;;掲示板の前まで移動
(send *pr2* :move-to (send (send *scene* :spot "/eng2/7f/before-elevator") :worldcoords) :world)
(send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")
(send *pr2* :move-to (make-coords :pos (send *pr2* :worldpos) :rpy (float-vector pi/2 0 0)) :world)
(send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")

;;ココでカメラが昨日と同じ位置に来るようにうまく調整したい

;;写真を撮る
(call-empty-service "/my_image_saver/save" :wait t)
(setq photo-num-before photo-num)
(incf photo-num)

;;ココで手動でポスターを一個追加する
(unix::sleep 30)

;;写真を撮る
(call-empty-service "/my_image_saver/save" :wait t)
(setq photo-num-after photo-num)
(incf photo-num)

;;2つの写真の差分を計算する
(setq file_name (ros::get-param "~file_name"))
(setq format_name (ros::get-param "~format_name"))
(setq req (instance hiraoka_semi::change_of_notice_boardRequest :init))
(send req :before (concatenate string file_name (string photo-num-before) format_name))
(send req :after (concatenate string file_name (string photo-num-after) format_name))
(setq res (ros::service-call "change_of_notice_board" req))

;;差分を保存する
;;ターゲットの位置まで近づいて、新たに写真を撮ってとできればいいなあ
(setq req (instance hiraoka_semi::image_parts_saver :init))
(send req :file_name filename)
(send req :format_name format_name)
(send req :parts (send res :changes))
(ros::service-call "image_parts_saver" req)

;;帰ってくる
(send *pr2* :init-pose)
(send *pr2* :move-to (send (send *scene* :spot "init-spot") :worldcoords) :world)
(send *irtviewer* :look-all *pr2*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
(send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")

