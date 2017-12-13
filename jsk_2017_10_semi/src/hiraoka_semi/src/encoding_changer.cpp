#include<ros/ros.h>
#include<opencv2/opencv.hpp>
#include<image_transport/image_transport.h>
#include<cv_bridge/cv_bridge.h>
#include<iostream>

using namespace std;
using namespace cv;

class ImageConverter{
  ros::NodeHandle nh_;
  image_transport::ImageTransport it_;
  image_transport::Subscriber img_sub_;
  image_transport::Publisher img_pub_;

public:  
  void image_callback(const sensor_msgs::ImageConstPtr &msg){
    cv_bridge::CvImagePtr in_ptr=cv_bridge::toCvCopy(msg);
    in_ptr->encoding="mono16";
    sensor_msgs::ImageConstPtr outmsg= in_ptr->toImageMsg();
    img_pub_.publish(outmsg);
    return;
  }
  
  ImageConverter(): nh_{}, it_(nh_) {
    img_pub_ = it_.advertise("encoding_changer/output",1);
    img_sub_ = it_.subscribe("image",3,&ImageConverter::image_callback,this);
  }

};

int main (int argc,char** argv){
  ros::init(argc,argv,"encoding_changer");
  ImageConverter ic{};
  ros::Rate loop_rate(30);
  
  while(ros::ok()){
    ros::spinOnce();
    loop_rate.sleep();
  }
  return 0;
}
