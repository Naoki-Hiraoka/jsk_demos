#!/usr/bin/env python

import rospy

import dynamic_reconfigure.client

def callback(config):
    rospy.loginfo("config")
    
if __name__ == "__main__":
    rospy.init_node("dynamic_client")
    
    rospy.wait_for_service("/image_publisher/set_parameters")
    print "service found"
    client = dynamic_reconfigure.client.Client("/image_publisher", timeout=30, config_callback=callback)
    print "client"
   # r = rospy.Rate(0.1)
  #  x = 0
 #   b = False
#    while not rospy.is_shutdown():
    #    x = x+1
     #   if x>10:
      #      x=0
      #  b = not b
    client.update_configuration({"file_name":"/home/mech-user/semi_ws/src/jsk_demos/jsk_2017_10_semi/src/hiraoka_semi/image/camera1.jpeg"})
    #    r.sleep()
