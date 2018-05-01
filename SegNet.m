

imgDir = 'H:\My Documents\GitHub\EEE6230-project-3\ISIC_TrainingData\Images';
labelDir = 'H:\My Documents\GitHub\EEE6230-project-3\ISIC_TrainingData\Labels';
%%Resize training images
% imgfiles = dir(fullfile(imgDir,'*.jpg'));
% labfiles = dir(fullfile(labelDir,'*.png'));
% NumberOfFiles = size(imgfiles);
%  for i=1:NumberOfFiles(1)
%      ImPath = fullfile(imgDir,imgfiles(i).name());
%      disp(ImPath)
%      NewIM = imresize(imread(ImPath), [360 480]);
%      imwrite(NewIM,ImPath);
%  end
% for i=1:NumberOfFiles(1)
%     ImPath = fullfile(labelDir,labfiles(i).name());
%     disp(ImPath)
%     NewIM = imresize(imread(ImPath), [360 480]);
%     imwrite(NewIM,ImPath);
% end

%set up the dataStores
imds = imageDatastore(imgDir);
%set yp the labels for the ground truth masks
LabelIDs = [0,255];
Classes = ["0", "255"]; %0 for skin 255 for lesion
pxds = pixelLabelDatastore(labelDir,Classes,LabelIDs);

%start of the network
imSize = [360 480 3];
numClasses = numel(Classes);

%graph of the original unchanged network
lGraph = segnetLayers(imSize,numClasses,'vgg16');
lGraph.Layers;
fig1 = figure();
subplot(1,2,1);
plot(lGraph);
subplot(1,2,1);
plot(lGraph);
axis off;
axis tight;
title('Complete Layer Graph');
subplot(1,2,2);
plot(lGraph); 
xlim([2.862 3.200]);
ylim([-0.9 10.9]);
axis off;
title('Last Nine Layers');

%Transfer Learning
% fig2 = figure('Position',[100,100,1000,1100]);
% subplot(1,2,1);
% plot(lGraph); 
% xlim([2.862 3.200]);
% ylim([-0.9 10.9]);
% axis off;
% title('Original Last Nine Layers');


lGraph = removeLayers(lGraph,{'pixelLabels'});
tbl = countEachLabel(pxds);
frequency = tbl.PixelCount/sum(tbl.PixelCount);


imFreq = tbl.PixelCount ./tbl.ImagePixelCount;
classWeights = median(imFreq) ./ imFreq;
pxLayer = pixelClassificationLayer('Name','Labels','ClassNames',tbl.Name, ...
    'ClassWeights',classWeights);

lGraph = addLayers(lGraph, pxLayer);
lGraph = connectLayers(lGraph,'softmax','Labels');
lGraph.Layers;

% subplot(1,2,2);
% plot(lGraph); 
% xlim([2.862 3.200]);
% ylim([-0.9 10.9]);
% axis off;
% title('new Last Nine Layers');

%%
%Training
disp('Training time!');


augmenter = imageDataAugmenter('RandXReflection',true, 'RandXTranslation', ...
    [-10 10],'RandYTranslation', [-10 10]);

dataSource = pixelLabelImageSource(imds,pxds,'DataAugmentation',augmenter);
options = trainingOptions('sgdm', 'InitialLearnRate', 0.001, 'MaxEpochs', ...
    10, 'MiniBatchSize', 2, 'plots','training-progress');
net= trainNetwork(dataSource,lGraph,options);
save('tenthEpoch','net')
% options = trainingOptions('sgdm', 'InitialLearnRate', 0.001, 'MaxEpochs', ...
%     5, 'MiniBatchSize', 1, 'plots','training-progress');
% net= trainNetwork(dataSource,lGraph,options);
% save('fithEpoch','net')
disp('NN Trained');
%%
%Compare groud truth vs predicted 
%load('thirdEpoch.mat');
%load('fithEpoch.mat');
pic_num = 10; % Arbituary number can be changed

I = readimage(imds,pic_num);
iB = readimage(pxds,pic_num);
IB = labeloverlay(I,iB);

C = semanticseg(I,net);
CB = labeloverlay(I,C);

figure;
imshowpair(IB,CB,'montage');
title('Ground truth vs predicted');

%%
%Run each testing network through the testing image set!

%change this set to the appropriate directories
%maybe include a function for getting inputs in the future
testIMGdir = 'H:\My Documents\GitHub\EEE6230-project-3\ISIC_TestData\Images';
ResultsDir = 'H:\My Documents\GitHub\EEE6230-project-3\Results-fithEpoch-2';
%
mkdir(ResultsDir);  %create the directory that the results go into. Gives a warning if it already exists
testIMGds = imageDatastore(testIMGdir);

index = 1:600;
%All this because my gpu can't run the standard test built into matlab

for i=index
    disp(i);
    I = readimage(testIMGds,i);
    result = semanticseg(I,net);        %returns a catagory array
    X = 1:360;
    Y = 1:480;
    doubleResult = zeros(360,480);      %this is going to be turned into an image
    for x = X
        for y =Y
            if (result(x,y) == "255")
                doubleResult(x,y) = 255;    %some image black magic fuckery            
            end           
        end
    end
    resultImgName = strcat(num2str(i),'.png');
    resultPath = fullfile(ResultsDir,resultImgName);
    imwrite(doubleResult,resultPath);   %Writes the semgentation mask to the results deirectory
end
disp('done');




%%
%This is where the tests are going to be written
%
ResultsDir = 'H:\My Documents\GitHub\EEE6230-project-3\Results-NoWeight';
GroundTruthdir = 'H:\My Documents\GitHub\EEE6230-project-3\ISIC_TestData\labels';
%
Classes = ["0","255"];      %0 for skin 255 for lesion
LabelIDs = [0,255];
GroundTruthds = pixelLabelDatastore(GroundTruthdir,Classes,LabelIDs);
restultLABELds = pixelLabelDatastore(ResultsDir,Classes,LabelIDs);


%Both of the testing directories need to be the same size
noGroundTruths = size(GroundTruthds.Files);
noGroundTruths = noGroundTruths(1); %number of ground truths
noResults = size(restultLABELds.Files);
noResults = noResults(1);   %number of tested images for that training time

if (noGroundTruths>noResults)
    sampleSize = noResults;
elseif(noGroundTruths<noResults)
    sampleSize = noGroundTruths;
else
    sampleSize = noGroundTruths;
end


%Sensitivity, specificty, accuracy and jaccard index
overallSensitivity = 0;
overallSpecificty = 0;
overallAccuracy = 0;
overallJaccard = 0;
for i=1:sampleSize
    GroumdTruth = readimage(GroundTruthds,i); %known truth
    TestImage = readimage(restultLABELds,i);  %mask that needs testing
    TP = 0; %True Positive
    TN = 0; %Trie Negative
    FP = 0; %False Positive
    FN = 0; %False Negative
    sensitivity = 0;
    specificty = 0;
    accuracy = 0;
    totalNoOfPixels = 360*480;
    disp(i);
    for x=1:360
        
        for y=1:480
            if ((GroumdTruth(x,y) == TestImage(x,y)) && (TestImage(x,y) == "255"))
                TP = TP +1;
                %disp("TP " + TP);
            elseif ((GroumdTruth(x,y) == TestImage(x,y)) && (TestImage(x,y) == "0"))
                TN = TN +1;
                %disp("TN " + TN);
            elseif ((GroumdTruth(x,y) ~= TestImage(x,y)) && (TestImage(x,y) == "255"))
                FP = FP+1;
                %disp("FP " + FP);
            elseif ((GroumdTruth(x,y) ~= TestImage(x,y)) && (TestImage(x,y) == "0"))
                FN = FN+1;
                %disp("FN " + FN);
            else
                disp("Pixel value undefined :(")
            end
        end
    end
    thisSensitivity = TP/(TP+FN);
    thisSpecificty = TN/(TN+FP);
    thisAccuracy = (TP+TN)/totalNoOfPixels;
    thisJaccard = jaccard(GroumdTruth,TestImage);   %returns 2 indexes, one for each catagory
    
    overallSensitivity = overallSensitivity + thisSensitivity;
    overallSpecificty = overallSpecificty + thisSpecificty;
    overallAccuracy = overallAccuracy + thisAccuracy;
    %overallJaccard = overallJaccard + thisJaccard;
    
    disp(i);
    disp("Sensitivity: " + thisSensitivity);
    disp("Specificty: " + thisSpecificty);
    disp("Accuracy: " + thisAccuracy);
    %disp("Jaccard: " + thisJaccard);
    
    
end

%make averages

overallSensitivity = overallSensitivity/sampleSize;
overallSpecificty = overallSpecificty/sampleSize;
overallAccuracy = overallAccuracy/sampleSize;
%overallJaccard = overallJaccard/sampleSize;

disp("Sensitivity: " + overallSensitivity);
disp("Specificty: " + overallSpecificty);
disp("Accuracy: " + overallAccuracy);
%disp("Jaccard: " + overallJaccard);

%%
%Jaccard index testing


ResultsDir = 'H:\My Documents\GitHub\EEE6230-project-3\Results-NoWeight';
GroundTruthdir = 'H:\My Documents\GitHub\EEE6230-project-3\ISIC_TestData\labels';
%
Classes = ["0","255"];      %0 for skin 255 for lesion
LabelIDs = [0,255];
GroundTruthds = pixelLabelDatastore(GroundTruthdir,Classes,LabelIDs);
restultLABELds = pixelLabelDatastore(ResultsDir,Classes,LabelIDs);


%Both of the testing directories need to be the same size
noGroundTruths = size(GroundTruthds.Files);
noGroundTruths = noGroundTruths(1); %number of ground truths
noResults = size(restultLABELds.Files);
noResults = noResults(1);   %number of tested images for that training time

if (noGroundTruths>noResults)
    sampleSize = noResults;
elseif(noGroundTruths<noResults)
    sampleSize = noGroundTruths;
else
    sampleSize = noGroundTruths;
end

overallJaccard = 0;
for i=1:sampleSize
    disp(i);
    GroumdTruth = readimage(GroundTruthds,i); %known truth
    TestImage = readimage(restultLABELds,i);  %mask that needs testing
    
    thisJaccard = jaccard(GroumdTruth,TestImage);
    overallJaccard = overallJaccard + thisJaccard;
end
overallJaccard = overallJaccard/sampleSize;

disp(overallJaccard);