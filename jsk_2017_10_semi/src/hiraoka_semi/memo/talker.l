#!/usr/bin/env roseus
;;;
;;; euslisp version of ros_tutorials/rospy_tutorials/001_talker_listener
;;;

(ros::load-ros-manifest "roseus")

;;;
(ros::roseus "hiraokatalker")
(ros::advertise "/pr2twit_from_tablet" roseus::stringStamped 1)
;;(ros::rate 100)
;;(while (ros::ok)
  (setq msg (instance std_msgs::string :init))
  (send msg :data "photo")
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "/pr2twit_from_tablet" msg)
  (ros::sleep)
;;  )

(do-until-key
 (print 1)
 )

(ros::roseus "shutdown")

