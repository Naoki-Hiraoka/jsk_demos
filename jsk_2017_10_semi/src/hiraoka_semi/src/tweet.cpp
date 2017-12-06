#include<ros/ros.h>
#include<opencv2/opencv.hpp>
#include<image_transport/image_transport.h>
#include<cv_bridge/cv_bridge.h>
#include<std_msgs/String.h>
#include<hiraoka_semi/tweet.h>

using namespace std;
using namespace cv;

class Tweet{
  ros::NodeHandle nh_;
  image_transport::ImageTransport it_;
  //image_transport::Subscriber img_sub_;
  image_transport::Publisher img_pub;//間違えです。imageの送信方法はこれではない
  ros::Publisher msg_pub;
  ros::ServiceServer service ;

public:
  bool srv_cb(hiraoka_semi::tweet::Request  &req,
	   hiraoka_semi::tweet::Response &res)
  {
    if(!req.message.empty()){
      std_msgs::String msg;
      msg.data = req.message;
      msg_pub.publish(msg);
      ROS_INFO("tweet: %s",req.message.c_str());
    }
    if(!req.image_file.empty()){
      Mat img=imread(req.image_file);
      if(img.data==nullptr){
	ROS_INFO("cannot open %s",req.image_file.c_str());
	return false;
      }
      cv_bridge::CvImagePtr out_ptr{new cv_bridge::CvImage{}};
      out_ptr->header.stamp=ros::Time::now();
      out_ptr->encoding="bgr8";
      out_ptr->image=std::move(img);
      sensor_msgs::ImageConstPtr outmsg= out_ptr->toImageMsg();
      img_pub.publish(outmsg);
      ROS_INFO("tweet: %s",req.image_file.c_str());
    }
    return true;
  }

  Tweet(): nh_{}, it_(nh_) {
    img_pub = it_.advertise("/tweet_image",1);
    msg_pub = nh_.advertise<std_msgs::String>("/tweet", 1);
    //img_sub_ = it_.subscribe("image",3,&Tweet::image_callback,this);
    service= nh_.advertiseService("tweet_sender", &Tweet::srv_cb,this);
  }
};

int main (int argc,char** argv){
  ros::init(argc,argv,"tweet_sender");
  Tweet tw{};
  ros::Rate loop_rate(30);
  ROS_INFO("service tweet start");
  
  while(ros::ok()){
    ros::spinOnce();
    loop_rate.sleep();
  }
  return 0;
}
