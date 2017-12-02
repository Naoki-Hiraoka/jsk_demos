#include<ros/ros.h>
#include<opencv2/opencv.hpp>
#include<image_transport/image_transport.h>
#include<cv_bridge/cv_bridge.h>
#include<dynamic_reconfigure/server.h>
#include<hiraoka_semi/background_subtractorConfig.h>
#include<iostream>

using namespace std;
using namespace cv;

class ImageConverter{
  ros::NodeHandle nh_;
  image_transport::ImageTransport it_;
  image_transport::Subscriber img_sub_;
  image_transport::Publisher img_pub_;
  Ptr<BackgroundSubtractorMOG2> background{};

  dynamic_reconfigure::Server<hiraoka_semi::background_subtractorConfig> server;
  dynamic_reconfigure::Server<hiraoka_semi::background_subtractorConfig>::CallbackType f;
public:  
  void image_callback(const sensor_msgs::ImageConstPtr &msg){
    ROS_INFO("image cb start");
    cv_bridge::CvImagePtr in_ptr=cv_bridge::toCvCopy(msg,"bgr8");
    Mat img=in_ptr->image;
    //    if(debug)cvtColor(img,img,COLOR_BGR2RGB);//usbcameraの場合はコメントアウトを外すこと
    Mat mask{};
    ROS_INFO("image cb if");
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
    ROS_INFO("image cb end");
    return;
  }
  
  void dynamic_callback(hiraoka_semi::background_subtractorConfig &config,uint32_t level){
    ROS_INFO("reconfigure: %s %s",config.filename.c_str(),config.topicname.c_str());
    if(!config.filename.empty()){
      VideoCapture video{config.filename};
      if(!video.isOpened()){
	ROS_INFO("Video cannot opened");
	return;
      }
      int flame_count=video.get(CV_CAP_PROP_FRAME_COUNT);
      background = createBackgroundSubtractorMOG2(flame_count,16,false);
      Mat img{};
      Mat mask{};

      while(video.read(img)){
	background->apply(img,mask);
      }      
    }
    if(!config.topicname.empty()){
      img_sub_.shutdown();
      img_sub_ = it_.subscribe(config.topicname.c_str(),3,&ImageConverter::image_callback,this);
    }
    ROS_INFO("reconfigure end");
  }

  ImageConverter(): nh_{}, it_(nh_),server{} {
    img_pub_ = it_.advertise("background_subtractor/output",1);
    img_sub_ = it_.subscribe("image",3,&ImageConverter::image_callback,this);
    f=boost::bind(&ImageConverter::dynamic_callback,this,_1,_2);
    server.setCallback(f);
  }

};

int main (int argc,char** argv){
  ros::init(argc,argv,"background_subtractor");
  ImageConverter ic{};
  ros::Rate loop_rate(30);
  
  while(ros::ok()){
    ros::spinOnce();
    loop_rate.sleep();
  }
  return 0;
}
