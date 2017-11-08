#include <opencv2/opencv.hpp>
#include <iostream>
#include <string>

using namespace std;
using namespace cv;

int main (void){
  VideoCapture cap{0};
  Mat image{};
  int num=0;
  
  namedWindow("camera",CV_WINDOW_AUTOSIZE);
  while(1){
    if(!cap.read(image)) cout<< "out"<<endl;
    imshow("camera",image);
    if(waitKey(33)=='a'){
      imwrite(string{"camera"} + to_string(num)+string{".jpeg"},image);
      num++;
    }
  }
}
