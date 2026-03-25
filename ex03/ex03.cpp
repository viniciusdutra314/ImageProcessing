#include <iostream>
#include <opencv2/core/mat.hpp>
#include <opencv2/opencv.hpp>

using namespace cv;

int main(int argc, char** argv )
{
    Mat M(2,2, CV_8UC3, Scalar(0,0,255));
    std::cout << "M = " << std::endl << " " << M << std::endl << std::endl;


    return 0;
}
