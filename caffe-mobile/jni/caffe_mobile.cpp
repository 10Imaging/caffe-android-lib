#include <string>
#include <android/log.h>
#include "caffe_mobile.hpp"

#define  LOG_TAG    "CAFFE_MOBILE"
#define  LOGV(...)  __android_log_print(ANDROID_LOG_VERBOSE,LOG_TAG, __VA_ARGS__)
#define  LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG, __VA_ARGS__)
#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG, __VA_ARGS__)
#define  LOGW(...)  __android_log_print(ANDROID_LOG_WARN,LOG_TAG, __VA_ARGS__)
#define  LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG, __VA_ARGS__)

using std::string;
using std::static_pointer_cast;
using std::clock;
using std::clock_t;

using caffe::Blob;
using caffe::Caffe;
using caffe::Datum;
using caffe::Net;
using caffe::shared_ptr;
using caffe::vector;
using caffe::MemoryDataLayer;

namespace caffe {

template <typename T>
vector<size_t> ordered(vector<T> const& values) {
	vector<size_t> indices(values.size());
	std::iota(begin(indices), end(indices), static_cast<size_t>(0));

	std::sort(
		begin(indices), end(indices),
		[&](size_t a, size_t b) { return values[a] > values[b]; }
	);
	return indices;
}

CaffeMobile::CaffeMobile(string model_path, string weights_path) {
	CHECK_GT(model_path.size(), 0) << "Need a model definition to score.";
	CHECK_GT(weights_path.size(), 0) << "Need model weights to score.";

	Caffe::set_mode(Caffe::CPU);

	clock_t t_start = clock();
	caffe_net = new Net<float>(model_path, caffe::TEST);
	caffe_net->CopyTrainedLayersFrom(weights_path);
	clock_t t_end = clock();
	LOG(DEBUG) << "Loading time: " << 1000.0 * (t_end - t_start) / CLOCKS_PER_SEC << " ms.";
}

CaffeMobile::~CaffeMobile() {
	free(caffe_net);
	caffe_net = NULL;
}

int CaffeMobile::test(string img_path) {
	CHECK(caffe_net != NULL);

	Datum datum;
	CHECK(ReadImageToDatum(img_path, 0, 256, 256, true, &datum));
	const shared_ptr<MemoryDataLayer<float>> memory_data_layer =
		static_pointer_cast<MemoryDataLayer<float>>(
			caffe_net->layer_by_name("data"));
	memory_data_layer->AddDatumVector(vector<Datum>({datum}));

	vector<Blob<float>* > dummy_bottom_vec;
	float loss;
	clock_t t_start = clock();
	const vector<Blob<float>*>& result = caffe_net->Forward(dummy_bottom_vec, &loss);
	clock_t t_end = clock();
	LOG(DEBUG) << "Prediction time: " << 1000.0 * (t_end - t_start) / CLOCKS_PER_SEC << " ms.";

	const float* argmaxs = result[1]->cpu_data();
	for (int i = 0; i < result[1]->num(); i++) {
		for (int j = 0; j < result[1]->height(); j++) {
			LOG(INFO) << " Image: "<< i << " class:"
			          << argmaxs[i*result[1]->height() + j];
		}
	}

	return argmaxs[0];
}

vector<caffe_result> create_results(vector<int>indices, vector<float>probs, int k){
    vector<caffe_result> results(k);
    for (int i=0; i<k; i++)
    {
        results[i].synset = indices[i];
        results[i].prob = probs[indices[i]];
    }
    return results;
}

vector<caffe_result> CaffeMobile::predict_top_k(string img_path, int k) {
    CHECK(caffe_net != NULL);
        
    Datum datum;
    CHECK(ReadImageToDatum(img_path, 0, 256, 256, true, &datum));
    const shared_ptr<MemoryDataLayer<float>> memory_data_layer =
        static_pointer_cast<MemoryDataLayer<float>>(caffe_net->layer_by_name("data"));
    memory_data_layer->AddDatumVector(vector<Datum>({datum}));
            
    float loss;
    vector<Blob<float>* > dummy_bottom_vec;
    clock_t t_start = clock();
    const vector<Blob<float>*>& result = caffe_net->Forward(dummy_bottom_vec, &loss);
    clock_t t_end = clock();
    LOG(DEBUG) << "Prediction time: " << 1000.0 * (t_end - t_start) / CLOCKS_PER_SEC << " ms.";
            
    const vector<float> probs = vector<float>(result[1]->cpu_data(), result[1]->cpu_data() + result[1]->count());
    CHECK_LE(k, probs.size());
    vector<size_t> sorted_index = ordered(probs);
            
    const vector<int> indices = vector<int>(sorted_index.begin(), sorted_index.begin() + k);
    return create_results(indices,probs,k);
}

//Image in should be RGB (3 channels)
vector<caffe_result> CaffeMobile::predict_top_k(cv::Mat& cv_img, int k) {
    CHECK(caffe_net != NULL);
            
    Datum datum;
    cv::Mat cv_img256;
    
    //Resize image to 256x256 which is expected by current net
    cv::resize(cv_img,cv_img256,cv::Size(256,256));

    CVMatToDatum(cv_img256, &datum);
    const shared_ptr<MemoryDataLayer<float>> memory_data_layer =
        static_pointer_cast<MemoryDataLayer<float>>(caffe_net->layer_by_name("data"));
    memory_data_layer->AddDatumVector(vector<Datum>({datum}));
                
    float loss;
    vector<Blob<float>* > dummy_bottom_vec;
    clock_t t_start = clock();
    const vector<Blob<float>*>& result = caffe_net->Forward(dummy_bottom_vec, &loss);
    clock_t t_end = clock();
    LOG(DEBUG) << "Prediction time: " << 1000.0 * (t_end - t_start) / CLOCKS_PER_SEC << " ms.";
                
    const vector<float> probs = vector<float>(result[1]->cpu_data(), result[1]->cpu_data() + result[1]->count());
    CHECK_LE(k, probs.size());
    vector<size_t> sorted_index = ordered(probs);
                
    const vector<int> indices = vector<int>(sorted_index.begin(), sorted_index.begin() + k);
    return create_results(indices,probs,k);
}

} // namespace caffe
