AUTHOR-Chris Wright

The segnet.m file contains the code that was used to train and test the segmentation algorithm. it was trained on the data from the 2017 ISIC challenge 
avaliable at https://challenge.kitware.com/#challenge/n/ISIC_2017%3A_Skin_Lesion_Analysis_Towards_Melanoma_Detection. The code contains sections for image 
resizing to the resolution reuired by VGG-16. 

To train the network change the file paths indicated by comments within the source code. The training options are as follows:
%%options%%
%optimiser: "SGDM"
%Learning rate: 0.001
%training cycles: 10
%batch size: 2(increasing this will take up more VRAM)
%plots the training progress in a convenient graph

The algorithm took approx. 1 hour per Epoch on a GTX 660 with 2GB of VRAM. Better hardware will yield faster trainig times.

Testing functions are included to calculate the accuracy, Sensitivity, specificity and Jaccard similarity idex.

Any questions on the segmentation algorithm should be directed to cwright7@sheffield.ac.uk