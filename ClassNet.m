
%Author Sai Krishnan
%% Loading a pretrained Network
alex = alexnet;                                                             %Load ALexnet
layers = alex.Layers;                                                       %Display the layers of the network
%%

layers(23) = fullyConnectedLayer(3);                                        %Change the number of fully connected layers to 3 in the 23rd layer
layers(25) = classificationLayer;                                           %Make the 25th layer a blank classification layer
%%

%Pre-processing the images

imgDir = 'H:\My Documents\GitHub\alexnet\myImages\SK';                      %Directory of training images
imgfiles = dir(fullfile(imgDir,'*.jpg'));                                   %List all files with .jpg 
NumberOfFiles = size(imgfiles);                                             %Specificy the number of files
for i=1:NumberOfFiles(1)                                                    %Create a for loop to resize the images
    ImPath = fullfile(imgDir,imgfiles(i).name());                           %Specify the image path
    disp(ImPath)                                        
    NewIM = imresize(imread(ImPath), [227 227]);                            %Resize to the size the network wants(227*227 for AlexNet).
    imwrite(NewIM,ImPath);                                                  %Rewrite the files back to the Image path
end

%%

%Set-up Image Datastores
allImages = imageDatastore('myImages', 'IncludeSubfolders', true, 'LabelSource', 'foldernames'); %Set up a imgae datastore for all the images

[trainingImages, testImages] = splitEachLabel(allImages, 0.9, 'randomize');                      %Split the data into two image datastores in 90:10 ratio, first used for training and later used for testing
%%

%Training our Network

disp('Training');
opts = trainingOptions('sgdm', 'InitialLearnRate', 0.001, 'maxEpochs', 20, 'MiniBatchSize', 64,'plots','training-progress'); %Specify the training options
myNet = trainNetwork(trainingImages, layers, opts);                                                                          %Train the network with the Training imagedatastore, with the specified training options over all the layers.
save('TrainedAlex','myNet')                                                                                                  %Save the trained Network.


%%

%Testing the trained network

NumberOfTests = size(testImages.Files);                                     %Obtaining the number of Test Images
NumberOfTests = NumberOfTests(1);

%True Positive(TP), False Positive(FP), True Negative(TN) and False
%Negative(FN) values for each classification.

TP_Mel = 0;                                                                 %True Positive Melanoma
TP_SK = 0;                                                                  %True Positive Seborrheic Keratosis
TP_Nev = 0;                                                                 %True Positive Nevus
FP_Mel = 0;                                                                 %False Positive Melanoma
FP_SK = 0;                                                                  %False Positive Seborrheic Keratosis
FP_Nev = 0;                                                                 %False Positive Nevus
TN_Mel = 0;                                                                 %True Negative Melanoma
TN_SK = 0;                                                                  %True Negative Seborrheic Keratosis
TN_Nev = 0;                                                                 %True Negative Nevus
FN_Mel = 0;                                                                 %False Negative Melanoma
FN_SK = 0;                                                                  %False Negative Seborrheic Keratosis
FN_Nev = 0;                                                                 %False Negative Nevus


%Testing the Classification in a binary manner.

for i=1:NumberOfTests                                                       %Formulate a for loop to Test if the image is True poitive or True Negative for any of the class
    disp(i);                                                                
    testLabel = testImages.Labels(i);                                       %Known Test Image Label of the Image
    testImage = readimage(testImages,i);
    predictedLabel = classify(myNet, testImage);                            %Predcited Label- Label of the Test Image classfied using our Network.
    if (testLabel == 'Melanoma') && (predictedLabel == testLabel)           %Check if, Test label is Melnoma and the Predicteed label is the same as test label.
        TP_Mel = TP_Mel +1;                                                 
        TN_SK = 0;
        TN_Nev = 0;
    elseif (testLabel == 'Nevus') && (predictedLabel == testLabel)          %Check if Test label is Nevus and the Predicteed label is Same as test label.
        TP_Nev = TP_Nev +1;                                                 
        TN_Mel = TN_Mel+1;                                                  
        TN_SK = TN_SK+1;                                                    
    elseif (testLabel == 'SK') && (predictedLabel == testLabel)             %Check if Test label is Nevus and the Predicteed label is Same as test label.
        TP_SK = TP_SK +1;                                                  
        TN_Mel = TN_Mel+1;                                                 
        TN_Nev = TN_Nev+1;                                                  
    elseif (testLabel == 'Melanoma') && (predictedLabel ~= testLabel)       %If Test label is not equal to predicted label
        if predictedLabel == 'Nevus'                                        %Check if Predicted Label is Nevus
            FP_Nev = FP_Nev +1;                                             
        elseif predictedLabel == 'SK'                                       %Check if Predicted Label is SK
            FP_SK = FP_SK +1;                                               
        end  
        FN_Mel = FN_Mel+1;                                                  
        
        %Repeat the same for Nevus and SK
        
        
    elseif (testLabel == 'Nevus') && (predictedLabel ~= testLabel)
        if predictedLabel == 'Melanoma'
             FP_Mel = FP_Mel +1;
        elseif predictedLabel == 'SK'
            FP_SK = FP_SK +1;
        end
        FN_Nev = FN_Nev +1;
    elseif (testLabel == 'SK') && (predictedLabel ~= testLabel)
        if predictedLabel == 'Melanoma'
             FP_Mel = FP_Mel +1;
        elseif predictedLabel == 'Nevus'
            FP_Nev = FP_Nev +1;
        end
        FN_SK = FN_SK +1;
    end    
end

%Calculate Sensitivity.

%Sesitivity is equal to TP/TP+FN

Sens_Mel = TP_Mel/(TP_Mel + FN_Mel);                                        %Sensitivity of Melanoma
Sens_Nev = TP_Nev/(TP_Nev + FN_Nev);                                        %Sensitivity of Nevus
Sens_SK = TP_SK/(TP_SK + FN_SK);                                            %Sensitivity of SK


%Specificty is equal to TN upon TN plus FP

Spec_Mel = TN_Mel/(TN_Mel+FP_Mel);                                          %Specificity of Melanoma
Spec_Nev = TN_Nev/(TN_Nev+FP_Nev);                                          %Specificity of Nevus
Spec_SK = TN_SK/(TN_SK+FP_SK);                                              %Specificity of SK

%Calculate accuracy

[predictedLabels,~] = classify(myNet, testImages);
accuracy = mean(predictedLabels == testImages.Labels);                      %Accuracy is the mean of True Positive labels.
disp(accuracy);

%%

%Plot ROC curves for each type

load('TrainedAlex')                                                         %Loading the saved Network
rngTestImages= shuffle(testImages);                                         %Shuffle the test Images for Testing
[predictedLabels,scores] = classify(myNet, rngTestImages);                  %Scores is the confidence the network has in that prediction                  

%Spliting the scores into each classification
melScores = scores(1:358);                                                  
nevScores = scores(359:716);
SKScores = scores(717:end);

%Defining each term to plot the curve
[X1,Y1,T1,AUC1] = perfcurve(predictedLabels,melScores,'Melanoma');
[X2,Y2,T2,AUC2] = perfcurve(predictedLabels,nevScores,'Nevus');
[X3,Y3,T3,AUC3] = perfcurve(predictedLabels,SKScores,'SK');


%plot(X1,Y1)                                                                %Plot Melanoma    
%plot(X2,Y2)                                                                %Plot Nevus
%plot(X3,Y3);                                                               %Plot SK

%Specify the labels of the Plot

xlabel('False positive rate') ;
ylabel('True positive rate');
title('ROC for Classification');



