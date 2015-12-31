#ifndef CAFFE_MOBILE_HPP_
#define CAFFE_MOBILE_HPP_

#include <string>
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include "caffe/caffe.hpp"

using std::string;

namespace caffe {

class caffe_result
{
public:
    int synset;
    float prob;
};
    
class CaffeMobile
{
public:
	CaffeMobile(string model_path, string weights_path);
	~CaffeMobile();

	int test(string img_path);
    
    //Image in should be RGB (3 channels)
    vector<caffe_result> predict_top_k(cv::Mat& cv_img, int k=3);
    
    vector<caffe_result> predict_top_k(string img_path, int k=3);

private:
	Net<float> *caffe_net;
};

} // namespace caffe

#endif
