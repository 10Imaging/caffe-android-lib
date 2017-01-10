package com.tenimaging.android.iris;

public class CaffeMobile {
    public native void setNumThreads(int numThreads);
    public native void enableLog(boolean enabled);
    public native int loadModel(String modelPath, String weightsPath);
    public native void unloadModel();
    private native void setMeanWithMeanFile(String meanFile);
    private native void setMeanWithMeanValues(float[] meanValues);
    public native void setScale(float scale);
    public native int predictImage(long imgLong,int numResults,int[] synsetList,float[] probList);
    public native int predictImagePath(String imgPath, int numResults,int[] synsetList,float[] probList);
    //gets features for each blob name.  Blobs are from deploy.prototxt.
    //For example call caffeMobile.extractFeatures("/sdcard/DCIM/test_flowers_1.jpg","fc8,prob");
    //returns an array of outputs for fc8 and prob
    public native float[][] extractFeatures(String imgPath, String blobNames);
    public void setMean(float[] meanValues) { setMeanWithMeanValues(meanValues); }
    public void setMean(String meanFile) { setMeanWithMeanFile(meanFile); }
}
