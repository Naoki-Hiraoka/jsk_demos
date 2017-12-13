#include "ros/ros.h"
#include "hiraoka_semi/video_recorder.h"
#include<string>
#include<thread>
using namespace std;

string message;

bool record(hiraoka_semi::video_recorder::Request  &req,
	 hiraoka_semi::video_recorder::Response &res)
{
  if(req.start&&req.stop){
    ROS_INFO("do nothing");
    return true;
  }
  if(req.start){
    message=string{"rosrun image_view video_recorder"};
    if(!req.topicname.empty())message+=string{" image:="}+req.topicname;
    if(!req.filename.empty())message+=string{" _filename:="}+req.filename;
    if(!req.nodename.empty())message+=string{" __name:="}+req.nodename;
    else message+=string{" __name:=recorder"};
    ROS_INFO("system: %s", message.c_str());
    thread t{system,message.c_str()};
    t.detach();
    return true;
  }
  if(req.stop){
    message=string{"rosnode kill"};
    if(!req.nodename.empty())message+=string{" "}+req.nodename;
    else message+=string{" recorder"};
    ROS_INFO("system: %s", message.c_str());
    thread t{system,message.c_str()};
    t.detach();
    return true;
  }
  ROS_INFO("do nothing");
  return true;
}

int main(int argc, char **argv)
{
  ros::init(argc, argv, "video_recorder");
  ros::NodeHandle n;

  ros::ServiceServer service = n.advertiseService("video_recorder", record);
  ROS_INFO("Ready to video_recorder.");
  ros::spin();

  return 0;
}
