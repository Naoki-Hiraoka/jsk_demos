#!/usr/bin/env roseus

;;rostopic pub -1 /hiraoka_semi/go_back std_msgs/Bool True　で終了

(ros::load-ros-manifest "roseus")
(ros::roseus "main")

(setq debug (ros::get-param "~debug"))
(setq move (ros::get-param "~move"))

(ros::load-ros-manifest "hiraoka_semi")
(ros::load-ros-manifest "dynamic_reconfigure")
(ros::load-ros-manifest "jsk_recognition_msgs")
(unless debug
  (load "package://hiraoka_semi/euslisp/tweet_sender.l"))
(when (and (not debug) move)
  (load "package://pr2eus/pr2-interface.l")
  (pr2-init)
  (load "package://jsk_maps/src/eng2-scene.l")
  (setq *scene* (make-eng2-scene))
  ;;掲示板を追加
  (setq *panel* (make-cube 3000 100 1500 :name "/eng2/7f/notice-board"))
  (send *panel* :move-to (make-coords :pos #F(2500 -26000 31000)) :world)
  (send *panel* :set-color :green)
  (objects (list *pr2* *scene* *panel*))
)

;;帰還指示を受け取るサブスクライバ
(setq go-back nil)
(ros::subscribe "/hiraoka_semi/go_back" std_msgs::bool #'(lambda (msg) (setq go-back (send msg :data))))

;;tweet回数
(setq *tweetnum* 0)

(when (and (not debug) move)
   ;;掲示板の前まで移動
  (pr2-tuckarm-pose)
  ;;(send *pr2* :move-to (send (send *scene* :spot "init-spot") :worldcoords) :world)
  (send *irtviewer* :look-all *pr2*)
  ;;(send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")
  ;;廊下
  (send *pr2* :move-to (make-coords :pos #f(-1000 5000 30002)) :world)
  ;;(send *pr2* :move-to (send (send (send *scene* :spot "/eng2/7f/before-elevator") :copy-worldcoords) :orient pi/2 :z) :world)
  (send *irtviewer* :look-all *pr2*)
  (x::window-main-one)
  (send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")
)

(ros::rate 10)

;;cameraが起動するのをまつ
(when debug
  (unix::sleep 5))
(block :mainloop
(while t
  (tagbody
   :start
   
   ;;beforeを記録する
   (ros::ros-info "start record")
   (speak-jp "記録開始")
   (setq *c_rgb* (instance ros::simple-action-client :init "/hiraoka_semi/background_subtractor2_rgb" hiraoka_semi::background_subtractor2Action))
   (setq goal (instance hiraoka_semi::background_subtractor2Actiongoal :init))
   (send goal :goal :frames 100)
   (send *c_rgb* :wait-for-server)
   (send *c_rgb* :send-goal goal)

   (setq *c_depth* (instance ros::simple-action-client :init "/hiraoka_semi/background_subtractor2_depth" hiraoka_semi::background_subtractor2Action))
   (setq goal (instance hiraoka_semi::background_subtractor2Actiongoal :init))
   (send goal :goal :frames 100)
   (send *c_depth* :wait-for-server)
   (send *c_depth* :send-goal goal)
   
   (send *c_rgb* :wait-for-result)
   (send *c_depth* :wait-for-result)
   (if (and (send (send *c_rgb* :get-result) :result) (send (send *c_depth* :get-result) :result))
       (ros::ros-info "record finished")
     (progn (ros::ros-info "record failed")
	    (go :start)))
   (speak-jp "記録完了。新しい掲示を待っています")
   ;;ココで手動でポスターを一個追加する
   (ros::ros-info "waiting for new paper")

   ;;新しい掲示を検出するまで待機。掲示を貼っている間は反応しないように。 10コマ連続
   (setq rgb_change_ok 0)
   (setq depth_change_ok 0)
   (ros::subscribe "/hiraoka_semi/countnonzero_rgb/output" std_msgs::Float64
		   #'(lambda (msg) (if (> (send msg :data) 0.01)
				       (incf rgb_change_ok)
				     (setq rgb_change_ok 0))))
   (ros::subscribe "/hiraoka_semi/countnonzero_depth/output" std_msgs::Float64
		   #'(lambda (msg) (if (< (send msg :data) 0.01)
				       (incf depth_change_ok)
				     (setq depth_change_ok 0))))
   (while (not (and (> rgb_change_ok 10) (> depth_change_ok 10)))
     (ros::sleep)
     (ros::spin-once)
     ;;帰還指示は出ていないか
     (when go-back
       (return-from :mainloop))
     )

   (speak-jp "新しい掲示を確認しました。tweetします。")
   ;;差分の位置を受信する
   (ros::subscribe "/hiraoka_semi/mask_image_to_rect_rgb/output" jsk_recognition_msgs::RectArray #'(lambda (msg) (setq rect (car (send msg :rects))) (setq time-now (send msg :header :stamp))))
   (setq time-target (ros::time-now))
   (send time-target :sec (+ (send time-target :sec) 3))
   (setq time-now (instance ros::time :init))
   (while (ros::time< time-now time-target)
     (ros::spin-once)
     (ros::sleep)
     )
   (ros::ros-info "diff was received")
   (ros::unsubscribe "/hiraoka_semi/mask_image_to_rect_rgb/output") 

   ;;rotated-rectに変換(rectarrayのx,yは左上の点)
   (setq change (instance opencv_apps::rotatedrect :init))
   (send change :angle 0.0)
   (send change :center :x (+ (send rect :x) (/ (send rect :width) 2)))
   (send change :center :y (+ (send rect :y) (/ (send rect :height) 2)))
   (send change :size :width (send rect :width))
   (send change :size :height (send rect :height))
   
   ;;差分を保存する
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
     (incf *tweetnum*)
     (setq message (concatenate string "newmessage" (string *tweetnum*)))
     (tweet-string #|"hello,jsk"|#message :with-image "/hiraoka_semi/change_image_publisher/output")
     (speak-jp "tweetしました。")
     )

   ;;帰還指示は出ていないか
   (ros::spin-once)
   (when go-back
     (return-from :mainloop))
   
   ))
);;mainloop

(ros::ros-info "go_back command was received")

(when (and (not debug) move)  
  ;;帰ってくる
  (send *pr2* :move-to (send (send *scene* :spot "init-spot") :worldcoords) :world)
  (send *irtviewer* :look-all *pr2*)
  (x::window-main-one)
  (send *ri* :move-to (send *pr2* :worldcoords) :frame-id "eng2")
)

(do-until-key
 (ros::sleep))

(exit)
