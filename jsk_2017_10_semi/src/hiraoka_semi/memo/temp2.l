(ros::roseus "hoge")
roslaunch hiraoka_semi video_recorder.launch
(unix::sleep 5)
rosnode kill video_recorder
(exit)
