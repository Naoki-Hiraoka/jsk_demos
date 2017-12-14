#include "ros/ros.h"
#include <opencv2/opencv.hpp>
#include<image_transport/image_transport.h>
#include<cv_bridge/cv_bridge.h>
#include<std_msgs/Float64.h>
#include<iostream>

using namespace std;
using namespace cv;

class MyCvPkg{
  image_transport::Subscriber img_sub_;
  ros::Publisher pub_;
  ros::NodeHandle nh_;
  image_transport::ImageTransport it_;
  ros::NodeHandle private_nh_;
  
  void imageCallback(const sensor_msgs::ImageConstPtr &msg){
    cv::Mat in_img = cv_bridge::toCvCopy(msg,msg->encoding)->image;
    if(in_img.empty())return;
    //write opencv code
    std_msgs::Float64 outmsg;
    outmsg.data=countNonZero(in_img)*1.0/(in_img.size().width*in_img.size().height);
    pub_.publish(outmsg);
    }
public:
  MyCvPkg(): nh_{},it_(nh_), private_nh_("~") {
    img_sub_ = it_.subscribe("image",3,&MyCvPkg::imageCallback,this);
    pub_ = private_nh_.advertise<std_msgs::Float64>("output",1);
  }
};

int main(int argc,char **argv){
  ros::init(argc,argv,"countnonzero");
  MyCvPkg mcp{};
  ros::spin();
}

