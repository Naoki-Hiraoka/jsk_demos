#include<opencv2/opencv.hpp>

using namespace cv;
int main(void){
  Mat img = imread("before.jpg");
  Range a{200,500};
  Range b{600,1000};
  imwrite("before1.jpg",img(a,b));
  return 0;
}
