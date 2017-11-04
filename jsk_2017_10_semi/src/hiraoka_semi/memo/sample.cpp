#include<iostream>
#include<sstream>
#include<string>
#include<iostream>
#include<iomanip>

using namespace std;
int main(void){
  stringstream ss;
  ss<<setw(4)<<setfill('0');
  ss<<1;
  string s;
  ss>>s;
  cout<<s;
  ss<<2;
  ss>>s;
  cout<<s;
  return 0;
}
