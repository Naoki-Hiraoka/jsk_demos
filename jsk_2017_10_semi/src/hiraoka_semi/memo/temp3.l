#!/usr/bin/env roseus

(ros::load-ros-manifest "roseus")
(load "package://pr2eus/pr2-interface.l")
(pr2-init)
(ros::rate 10)
(do-until-key
 (print "loop")
 (ros::sleep)
 )
(exit)
