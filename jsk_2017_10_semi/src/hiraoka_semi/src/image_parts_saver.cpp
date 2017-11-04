#include "ros/ros.h"
#include "hiraoka_semi/image_parts_saver.h"
#include <opencv2/opencv.hpp>
#include<cmath>

bool image_parts_save(hiraoka_semi::image_parts_saver::Request  &req,
		   hiraoka_semi::image_parts_saver::Response &res)
{
  ROS_INFO("request: image=%s, parts_num=%ld", (req.file_name+req.format_name).c_str(), req.parts.size());
  cv::Mat image = cv::imread(req.file_name+req.format_name);
  res.names.clear();
  
  for(int i=0;i<req.parts.size();i++){
    auto part=req.parts[i];
    if(abs(part.angle) < 10/*deg?*/){
      cv::imwrite(req.file_name+"_part"+std::to_string(i)+req.format_name,image(cv::Range{(int)(part.center.y-part.size.height/2),(int)(part.center.y+part.size.height/2)},cv::Range{(int)(part.center.x-part.size.width/2),(int)(part.center.x+part.size.width/2)}));
    }else{
      float angle = part.angle;
      //回し過ぎを防ぐ
      int rotnum=0;
      while(angle>45){angle-=90;rotnum++;}
      while(angle<-45){angle+=90;rotnum++;}
      int width,height;
      cv::Mat dst{};
      cv::Mat affine = cv::getRotationMatrix2D(cv::Point{(int)part.center.x,(int)part.center.y},angle,1);
      cv::warpAffine(image,dst,affine,cv::Size{image.rows,image.cols});
      if(rotnum%2==0){
	cv::imwrite(req.file_name+"_part"+std::to_string(i)+req.format_name,image(cv::Range{(int)(part.center.y-part.size.height/2),(int)(part.center.y+part.size.height/2)},cv::Range{(int)(part.center.x-part.size.width/2),(int)(part.center.x+part.size.width/2)}));
      }else{
	cv::imwrite(req.file_name+"_part"+std::to_string(i)+req.format_name,image(cv::Range{(int)(part.center.y-part.size.width/2),(int)(part.center.y+part.size.width/2)},cv::Range{(int)(part.center.x-part.size.height/2),(int)(part.center.x+part.size.height/2)}));
      }
    }
    res.names.push_back(req.file_name+"_part"+std::to_string(i)+req.format_name);
  }
  ROS_INFO("succeed");
  return true;
}

int main(int argc, char **argv)
{
  ros::init(argc, argv, "image_parts_saver");
  ros::NodeHandle n;
  ros::ServiceServer service = n.advertiseService("image_parts_saver", image_parts_save);
  ROS_INFO("Ready to save image parts");
  ros::spin();

  return 0;
}
