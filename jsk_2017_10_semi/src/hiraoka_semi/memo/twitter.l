#!usr/bin/env roseus

(ros::load-ros-manifest "roseus")
(load "package://jsk_robot_startup/lifelog/tweet_client.l")

(defun twit-cb (msg)
  (let ((twit-str (send msg :data)))
    (format t "msg received")
    (tweet-string twit-str
		  :warning-time 5
		  :with-image #|"/tablet/marked/image_rect_color"|#"/l_forearm_cam/image_color")))

(ros::roseus "hiraokatwitter")
(ros::subscribe "/pr2twit_from_tablet" roseus::StringStamped #'twit-cb)

(do-until-key
 (ros::spin-once)
 )
