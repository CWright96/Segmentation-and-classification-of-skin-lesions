
alex = alexnet;
layers = alex.Layers;
%%
layers(23) = fullyConnectedLayer(3);
layers(25) = classificationLayer;
%%
imgDir = 'H:\My Documents\GitHub\alexnet\myImages\SK'
imgfiles = dir(fullfile(imgDir,'*.jpg'));
NumberOfFiles = size(imgfiles);
for i=1:NumberOfFiles(1)
    ImPath = fullfile(imgDir,imgfiles(i).name());
    disp(ImPath)
    NewIM = imresize(imread(ImPath), [227 227]);
    imwrite(NewIM,ImPath);
end

%%
%myImages = imresize('H:\My Documents\GitHub\alexnet\myImages',[227,227]);
allImages = imageDatastore('myImages', 'IncludeSubfolders', true, 'LabelSource', 'foldernames');

[trainingImages, testImages] = splitEachLabel(allImages, 0.8, 'randomize');
%%
opts = trainingOptions('sgdm', 'InitialLearnRate', 0.001, 'maxEpochs', 20, 'MiniBatchSize', 64,'plots','training-progress');
myNet = trainNetwork(trainingImages, layers, opts);
save('TrainedAlex','myNet')

%%


disp('Running');

NumberOfTests = size(testImages.Files);
NumberOfTests = NumberOfTests(1);
TP_Mel = 0;
TP_SK = 0;
TP_Nev = 0;
FP_Mel = 0;
FP_SK = 0;
FP_Nev = 0;
TN_Mel = 0;
TN_SK = 0;
TN_Nev = 0;
FN_Mel = 0;
FN_SK = 0;
FN_Nev = 0;
for i=1:NumberOfTests
    disp(i);
    testLabel = testImages.Labels(i);%known truth
    testImage = readimage(testImages,i);
    predictedLabel = classify(myNet, testImage);
    if (testLabel == 'Melanoma') && (predictedLabel == testLabel);
        TP_Mel = TP_Mel +1;
        TN_SK = 0;
        TN_Nev = 0;
    elseif (testLabel == 'Nevus') && (predictedLabel == testLabel);
        TP_Nev = TP_Nev +1;
        TN_Mel = TN_Mel+1;
        TN_SK = TN_SK+1;
    elseif (testLabel == 'SK') && (predictedLabel == testLabel);
        TP_SK = TP_SK +1;
        TN_Mel = TN_Mel+1;
        TN_Nev = TN_Nev+1;
    elseif (testLabel == 'Melanoma') && (predictedLabel ~= testLabel);
        if predictedLabel == 'Nevus'
            FP_Nev = FP_Nev +1;
        elseif predictedLabel == 'SK'
            FP_SK = FP_SK +1;
        end  
        FN_Mel = FN_Mel+1;
    elseif (testLabel == 'Nevus') && (predictedLabel ~= testLabel);
        if predictedLabel == 'Melanoma'
             FP_Mel = FP_Mel +1;
        elseif predictedLabel == 'SK'
            FP_SK = FP_SK +1;
        end
        FN_Nev = FN_Nev +1;
    elseif (testLabel == 'SK') && (predictedLabel ~= testLabel);
        if predictedLabel == 'Melanoma'
             FP_Mel = FP_Mel +1;
        elseif predictedLabel == 'Nevus'
            FP_Nev = FP_Nev +1;
        end
        FN_SK = FN_SK +1;
    end    
end

Sens_Mel = TP_Mel/(TP_Mel + FN_Mel);
Sens_Nev = TP_Nev/(TP_Nev + FN_Nev);
Sens_SK = TP_SK/(TP_SK + FN_SK);

Spec_Mel = TN_Mel/(TN_Mel+FP_Mel);
Spec_Nev = TN_Nev/(TN_Nev+FP_Nev);
Spec_SK = TN_SK/(TN_SK+FP_SK);


predictedLabels = classify(myNet, testImages);
accuracy = mean(predictedLabels == testImages.Labels);
disp(accuracy);
