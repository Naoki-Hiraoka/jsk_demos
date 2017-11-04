#include<opencv2/opencv.hpp>
#include<iostream>
using namespace std;
using namespace cv;
int main(void){
  vector<Point> contour;
  contour.push_back(Point2f(0, 0));
  contour.push_back(Point2f(10, 0));
  contour.push_back(Point2f(10, 10));
  contour.push_back(Point2f(5, 4));
  
  double area0 = contourArea(contour);
  vector<Point> approx;
  approxPolyDP(contour, approx, 5, true);
  double area1 = contourArea(approx);
  
  cout << "area0 =" << area0 << endl <<
    "area1 =" << area1 << endl <<
    "approx poly vertices" << approx.size() << endl;
  return 0;
}
