#include<ros/ros.h>
#include<opencv2/opencv.hpp>
#include<image_transport/image_transport.h>
#include<cv_bridge/cv_bridge.h>
#include<iostream>
#include<string>

using namespace std;
using namespace cv;

class ImageConverter{
  ros::NodeHandle nh_;
  ros::NodeHandle local_nh;
  image_transport::ImageTransport it_;
  image_transport::Subscriber img_sub_;

  VideoWriter video;
  string filename;
  string codec;
  int fps;

  int count=0;
  
public:  
  void image_callback(const sensor_msgs::ImageConstPtr &msg){
    cv_bridge::CvImagePtr in_ptr=cv_bridge::toCvCopy(msg);
    Mat img;
    cvtColor(in_ptr->image,img,COLOR_GRAY2BGR);
    count++;
    ROS_INFO_STREAM("Recording frame " << count << "\x1b[1F");
    video<<(img);
    imshow("camera",img);
    cv::waitKey(3);
    return;
  }
  
  ImageConverter(): nh_{}, it_(nh_),local_nh("~") {
    img_sub_ = it_.subscribe("image",3,&ImageConverter::image_callback,this);
    local_nh.param("filename", filename, std::string("output.avi"));
    local_nh.param("fps", fps, 15);
    local_nh.param("codec", codec, std::string("MJPG"));

    cv::Size size(640,480);
    
    video.open(filename,
		   cv::VideoWriter::fourcc(codec.c_str()[0],
					   codec.c_str()[1],
					   codec.c_str()[2],
					   codec.c_str()[3]),
		   fps,
		   size,
		   true);

    namedWindow("camera");
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
