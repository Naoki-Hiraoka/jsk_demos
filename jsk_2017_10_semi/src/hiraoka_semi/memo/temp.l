(ros::load-ros-manifest "roseus")
(ros::roseus "hoge")
(ros::advertise "/image_time_diff/start" std_msgs::Header 10)
(setq msg (instance std_msgs::Header :init))


(ros::rate 10)
(while (not (ros::get-topic-publisher "/image_time_diff/start"))
  (ros::sleep))

(setq i 0)
(while (< i 10)
  (send msg :seq i)
  (send msg :stamp (ros::time-now))
  (ros::publish "/image_time_diff/start" msg)
  (incf i)
  (ros::sleep)
  )

(exit)
