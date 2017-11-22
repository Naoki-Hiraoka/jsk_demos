
#include "ros/ros.h"
#include <opencv2/opencv.hpp>
#include<image_transport/image_transport.h>
#include<cv_bridge/cv_bridge.h>

class MyCvPkg{
  image_transport::Subscriber img_sub_;
  image_transport::ImageTransport it_;
  image_transport::Publisher img_pub_;
  
  void imageCallback(const sensor_msgs::ImageConstPtr &msg){
    ROS_INFO("Received image");
    cv::Mat in_img = cv_bridge::toCvCopy(msg,msg->encoding)->image;

    //write opencv code
    cv::Mat out_img{};
    cv::GaussianBlur(in_img,out_img,cv::Size{5,5},1);

    cv_bridge::CvImagePtr out_ptr{cv_bridge::toCvCopy(msg,msg->encoding)};
    out_ptr->image=std::move(out_img);
    sensor_msgs::ImageConstPtr outmsg= out_ptr->toImageMsg();
    img_pub_.publish(outmsg);
  }
public:
  MyCvPkg(ros::NodeHandle nh = ros::NodeHandle()) :it_(nh){
    img_sub_ = it_.subscribe("image",3,&MyCvPkg::imageCallback,this);
    img_pub_ = it_.advertise("gaussian_output",1);
  }
};

int main(int argc,char **argv){
  ros::init(argc,argv,"my_cv_pkg_node");
  MyCvPkg mcp;
  ros::spin();
}

