
#include "ros/ros.h"
#include "hiraoka_semi/change_of_notice_board.h"
#include <opencv2/opencv.hpp>
#include "detect_squares.h"

bool is_like(std::vector<cv::Point>& before,std::vector<cv::Point>& after){
  //afterの面積　と、　beforeとafterの積の図形の面積　の比をみる
  double area_after = cv::contourArea(after);
  std::vector<cv::Point2f> intersection{};
  if(cv::rotatedRectangleIntersection(cv::minAreaRect(before),cv::minAreaRect(after),intersection)){
    double area_sum = cv::contourArea(intersection);
    if(area_sum/area_after>0.5) return true;
  }
  return false;
}

void reduce_squares(std::vector<std::vector<cv::Point>>& src,std::vector<std::vector<cv::Point>>& dst){
  std::vector<std::vector<cv::Point>> temp{};

  //remove the border reference: https://github.com/alyssaq/opencv/blob/master/squares.cpp
  for(auto& square:src){
    if ( square[0].x > 3 && square[0].y > 3)
      temp.push_back(square);
  }

  //似ている図形どうし分類
  int type_num = 0;
  std::vector<int> type_ref(temp.size(),-1);
  std::vector<std::vector<std::vector<cv::Point>>> types{};
  for(int i=0;i<temp.size();i++){
    for(int j=0;j<i;j++){
      if(type_ref[i]==-1&&is_like(temp[j],temp[i])){
	type_ref[i]=type_ref[j];
	types[type_ref[i]].push_back(temp[i]);
      }
    }
    if(type_ref[i]==-1){
      type_ref[i]=type_num;
      types.push_back(std::vector<std::vector<cv::Point>>{temp[i]});
      type_num++;
    }
  }

  //最も面積が大きいものを代表とする
  temp.clear();
  for(auto& contours:types){
    double max=0;
    std::vector<cv::Point> max_contour{};
    for(auto& contour:contours){
      double area=cv::contourArea(contour);
      if(area>max){
	max = area;
	max_contour=contour;
      }
    }
    temp.push_back(std::move(max_contour));
  }
  
  dst=std::move(temp);
}

std::vector<std::vector<cv::Point>> compare_squares(std::vector<std::vector<cv::Point>>& before,std::vector<std::vector<cv::Point>>& after){
  std::vector<std::vector<cv::Point>> result{};
  for(auto& contour_a:after){
    bool new_contour = true;
    for(auto contour_b:before){
      if(is_like(contour_a,contour_b))
	new_contour=false;
    }
    if(new_contour)result.push_back(contour_a);
  }
  return result;
}

bool detect_change(hiraoka_semi::change_of_notice_board::Request  &req,
		   hiraoka_semi::change_of_notice_board::Response &res)
{
  ROS_INFO("request: x=%s, y=%s", req.before.c_str(), req.after.c_str());
  cv::Mat before_img = cv::imread(req.before);
  cv::Mat after_img = cv::imread(req.after);
  /*
  cv::namedWindow("before",cv::WINDOW_AUTOSIZE);
  cv::imshow("before",before_img);
  cv::namedWindow("after",cv::WINDOW_AUTOSIZE);
  cv::imshow("after",before_img);
  cv::waitKey(1);
  */

  //ココで2つの画像の傾きなどを補正したい
  
  //detect_squares.h reference: https://github.com/alyssaq/opencv/blob/master/squares.cpp
  std::vector<std::vector<cv::Point>> before_squares{};
  findSquares(before_img,before_squares);
  std::vector<std::vector<cv::Point>> after_squares{};
  findSquares(after_img,after_squares);

  //reduce square
  reduce_squares(before_squares,before_squares);
  reduce_squares(after_squares,after_squares);

  //compare square
  std::vector<std::vector<cv::Point>> result_squares=compare_squares(before_squares,after_squares);

  cv::namedWindow("changes");
  drawSquares(after_img,result_squares,"changes");
  cv::waitKey(0);
  cv::destroyWindow("changes");
  
  res.changes.clear();
  for(auto& square: result_squares){
    cv::RotatedRect rect = minAreaRect(square);
    opencv_apps::RotatedRect temp{};
    temp.angle = rect.angle;
    temp.center.x = rect.center.x;
    temp.center.y = rect.center.y;
    temp.size.width = rect.size.width;
    temp.size.height = rect.size.height;
    res.changes.push_back(std::move(temp));
  }
  ROS_INFO("sending back response size: %d", (int)res.changes.size());
  return true;
}

int main(int argc, char **argv)
{
  ros::init(argc, argv, "change_of_notice_board_server");
  ros::NodeHandle n;
  ros::ServiceServer service = n.advertiseService("change_of_notice_board", detect_change);
  ROS_INFO("Ready to detect change of notice board");
  ros::spin();

  return 0;
}
