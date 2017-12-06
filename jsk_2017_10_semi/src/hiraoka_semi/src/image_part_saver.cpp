#include "ros/ros.h"
#include "hiraoka_semi/image_part_saver.h"
#include <opencv2/opencv.hpp>
#include<image_transport/image_transport.h>
#include<cv_bridge/cv_bridge.h>
#include<cmath>

using namespace std;
using namespace cv;

class MyCvPkg{
  ros::NodeHandle nh_;
  image_transport::Subscriber img_sub_;
  image_transport::ImageTransport it_;
  image_transport::Publisher img_pub_;
  ros::ServiceServer service;
  Mat img{};
  
  void imageCallback(const sensor_msgs::ImageConstPtr &msg){
    img = cv_bridge::toCvCopy(msg,"bgr8")->image;

    return;
  }

  bool image_part_save(hiraoka_semi::image_part_saver::Request  &req,
		       hiraoka_semi::image_part_saver::Response &res){
    ROS_INFO("request: file_name=%s, parts_num=%ld", req.file_name.c_str(), req.parts.size());
    cvtColor(img,img,COLOR_BGR2RGB);
    for(int i=0;i<1/*req.parts.size()*/;i++){
      auto part=req.parts[i];
      if(abs(part.angle) < 10/*deg?*/){
	cv::imwrite(req.file_name,img(cv::Range{(int)(part.center.y-part.size.height/2),(int)(part.center.y+part.size.height/2)},cv::Range{(int)(part.center.x-part.size.width/2),(int)(part.center.x+part.size.width/2)}));
      }else{
	float angle = part.angle;
	//回し過ぎを防ぐ
	int rotnum=0;
	while(angle>45){angle-=90;rotnum++;}
	while(angle<-45){angle+=90;rotnum++;}
	int width,height;
	cv::Mat dst{};
	cv::Mat affine = cv::getRotationMatrix2D(cv::Point{(int)part.center.x,(int)part.center.y},angle,1);
	cv::warpAffine(img,dst,affine,cv::Size{img.rows,img.cols});
	if(rotnum%2==0){
	  cv::imwrite(req.file_name,img(cv::Range{(int)(part.center.y-part.size.height/2),(int)(part.center.y+part.size.height/2)},cv::Range{(int)(part.center.x-part.size.width/2),(int)(part.center.x+part.size.width/2)}));
	}else{
	  cv::imwrite(req.file_name,img(cv::Range{(int)(part.center.y-part.size.width/2),(int)(part.center.y+part.size.width/2)},cv::Range{(int)(part.center.x-part.size.height/2),(int)(part.center.x+part.size.height/2)}));
	}
      }
    }
    ROS_INFO("succeed");
    return true;
  }
  
  
public:
  MyCvPkg() :it_(nh_){
    img_sub_ = it_.subscribe("image",3,&MyCvPkg::imageCallback,this);
    service = nh_.advertiseService("image_part_saver", &MyCvPkg::image_part_save,this);
  }
};



int main(int argc, char **argv)
{
  ros::init(argc, argv, "image_part_saver");
  MyCvPkg mcp;
  ROS_INFO("Ready to save image part");
  ros::spin();

  return 0;
}
