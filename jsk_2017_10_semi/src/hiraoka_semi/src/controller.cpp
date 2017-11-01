#include<ros/ros.h>
#include<opencv2/opencv.hpp>
#include<image_transport/image_transport.h>
#include<cv_bridge/cv_bridge.h>
#include<std_msgs/String.h>
#include<string>

using namespace cv;
using namespace std;

int pre_x=0, pre_y=0;
void onMouse(int event,int x,int y,int flags,void* pub){
  std_msgs::String msg;
  switch(event){
  case EVENT_LBUTTONDOWN:
    pre_x = x;
    pre_y = y;
    break;
  case EVENT_MOUSEMOVE:
    if(flags&EVENT_FLAG_LBUTTON){
      if(abs(x-pre_x)>=abs(y-pre_y)){
	if(x>pre_x){
	  msg.data=String{"look-left"};
	}else{
	  msg.data=String{"look-right"};
	}
      }else{
	if(y>pre_y){
	  msg.data=String{"look-down"};
	}else{
	  msg.data=String{"look-up"};
	}
      }
      reinterpret_cast<ros::Publisher*>(pub)->publish(msg);
      pre_x=x;
      pre_y=y;
    }
    break;
  default:
    break;
  }
}

class MyCvPkg
{
private:
  image_transport::Subscriber img_sub_;
  image_transport::ImageTransport it_;
  ros::Publisher pub_;
  
  void imageCallBack(const sensor_msgs::ImageConstPtr &img_msg){
    ROS_INFO("image received");
    Mat in_img=cv_bridge::toCvCopy(img_msg,img_msg->encoding)->image;
    cvtColor(in_img,in_img,COLOR_RGB2BGR);
    imshow("controller",in_img);
    
    char key = waitKey(1);
    onkey(key);
    return;
  }

  void onkey(char key){
    //ROS_INFO(to_string(static_cast<int>(key)).c_str());
    std_msgs::String msg{};
    bool send=false;
    switch(key){
    case 'w':
      msg.data=String{"move-forward"};
      break;
    case 's':
      msg.data=String{"move-backward"};
      break;
    case 'd':
      msg.data=String{"move-right"};
      break;
    case 'a':
      msg.data=String{"move-left"};
      break;
    case 'e':
      msg.data=String{"turn-right"};
      break;
    case 'q':
      msg.data=String{"turn-left"};
      break;
    case 'r':
      msg.data=String{"update"};
      break;
    case 'u':
      msg.data=String{"hand-up"};
      break;
    case 'k':
      msg.data=String{"hand-right"};
      break;
    case 'h':
      msg.data=String{"hand-left"};
      break;
    case 'j':
      msg.data=String{"hand-down"};
      break;
    case 'y':
      msg.data=String{"hand-forward"};
      break;
    case 'i':
      msg.data=String{"hand-backward"};
      break;
    default:
      break;
    }
    if(msg.data!=""){
      pub_.publish(msg);
    }
  }

public:
  MyCvPkg(ros::NodeHandle nh ,ros::Publisher pub):it_(nh), pub_(pub)
  {
    img_sub_ = it_.subscribe("image",3,&MyCvPkg::imageCallBack,this);
    namedWindow("controller",1);
    setMouseCallback("controller",onMouse,&pub_);
  }
};

int main(int argc,char **argv){
  ros::init(argc,argv,"controller");
  ros::NodeHandle n;
  ros::Publisher pub = n.advertise<std_msgs::String>("/controller", 100);
  MyCvPkg mcp{n,pub};
  ros::Rate loop_rate(10);
  ros::spin();
}


/*
std_msgs::String msg;
msg.data = ss.str();
chatter_pub.publish(msg);
ros::spinOnce();
loop_rate.sleep();
*/
