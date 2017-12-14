#include<ros/ros.h>
#include<opencv2/opencv.hpp>
#include<image_transport/image_transport.h>
#include<cv_bridge/cv_bridge.h>
#include<hiraoka_semi/background_subtractor2Action.h>
#include<actionlib/server/simple_action_server.h>
#include<iostream>

using namespace std;
using namespace cv;

class ImageConverter{
  ros::NodeHandle nh_;
  ros::NodeHandle private_nh_;
  image_transport::ImageTransport it_;
  image_transport::ImageTransport private_it_;
  image_transport::Subscriber img_sub_;
  image_transport::Publisher img_pub_;
  Ptr<BackgroundSubtractorMOG2> background{};
  actionlib::SimpleActionServer<hiraoka_semi::background_subtractor2Action> server;
  hiraoka_semi::background_subtractor2Feedback feedback_;
  hiraoka_semi::background_subtractor2Result result_;

  int frame_count;
  int count=0;
  bool train=false;
  Ptr<BackgroundSubtractorMOG2> newbackground{};
public:  
  void image_callback(const sensor_msgs::ImageConstPtr &msg){
    cv_bridge::CvImagePtr in_ptr=cv_bridge::toCvCopy(msg);
    Mat img=in_ptr->image;
    Mat mask{};
    if(train){
      if(server.isPreemptRequested()){
	train=false;
	server.setPreempted();
	ROS_INFO_STREAM(endl<<"Preempted");
      }else if(count==frame_count){
	background=move(newbackground);
	train=false;
	result_.result=true;
	server.setSucceeded(result_);
	ROS_INFO_STREAM(endl<<"Finished");
      }else{
	newbackground->apply(img,mask);
	count++;
	feedback_.rest=frame_count-count;
	server.publishFeedback(feedback_);
	ROS_INFO_STREAM("Recording frame " << count << "\x1b[1F");
      }
    }
    if(background==nullptr)return;
    background->apply(img,mask,0);
    mask.convertTo(mask,CV_8UC1);
    threshold(mask,mask,254,255,THRESH_TOZERO);
    morphologyEx(mask,mask,MORPH_OPEN,getStructuringElement(MORPH_RECT,Size{3,3}));
    cv_bridge::CvImagePtr out_ptr{new cv_bridge::CvImage{}};
    out_ptr->header=in_ptr->header;
    out_ptr->encoding="mono8";
    out_ptr->image=std::move(mask);
    sensor_msgs::ImageConstPtr outmsg= out_ptr->toImageMsg();
    img_pub_.publish(outmsg);
    
    return;
  }

  void action_callback(const hiraoka_semi::background_subtractor2GoalConstPtr &goal){
    if(goal->frames>0)frame_count=goal->frames;
    else frame_count=100;
    newbackground = createBackgroundSubtractorMOG2(frame_count,16,false);
    count=0;
    feedback_.rest=frame_count;
    train=true;
    ros::Rate loop_rate(30);
    while(train&&ros::ok()){
      ros::spinOnce();
      loop_rate.sleep();
    }
  }
  
  ImageConverter(): nh_{},private_nh_("~") ,it_(nh_),private_it_(private_nh_),
		    server{private_nh_,"",boost::bind(&ImageConverter::action_callback,this,_1),false}
  {
    img_pub_ = private_it_.advertise("output",1);
    img_sub_ = it_.subscribe("image",3,&ImageConverter::image_callback,this);
    server.start();
    ROS_INFO_STREAM("background_subtractor2 prepared");
  }
};

int main (int argc,char** argv){
  ros::init(argc,argv,"background_subtractor2");
  ImageConverter ic{};
  ros::Rate loop_rate(30);
  
  while(ros::ok()){
    ros::spinOnce();
    loop_rate.sleep();
  }
  return 0;
}
