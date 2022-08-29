%% Creation of Testing and Training Datasets

%import feature values
SelectedFeatureValueMatrix = FeatureValues(:, ["labels", "maxPower", "kurt", "pulsePeakiness", "teW", "stDev"]);

%split validation data into a training set and a testing set
trainingFeatures = table();
trainingWaveforms = table();
testFeatures = table();
testWaveforms = table();

for i = 1:2736
    randN = rand;
    if randN <= 0.2
        testFeatures = [testFeatures;SelectedFeatureValueMatrix(i,:)];
        testWaveforms = [testWaveforms;AllWaveforms(i, 1:2)];
    else
        trainingFeatures = [trainingFeatures;SelectedFeatureValueMatrix(i,:)];
        trainingWaveforms = [trainingWaveforms;AllWaveforms(i, 1:2)];
    end
end

%check number of leads in test set to ensure 80/20 split
testLabels = table2array(testFeatures(:,1));
numberOfLeads = 0;
for i = 1:length(testLabels)
    if testLabels(i) == 'lead'
        numberOfLeads = numberOfLeads+1;
    else
    end
end

%% Clustering
kmedoidTraining = table2array(trainingFeatures(:, ["maxPower", "kurt", "pulsePeakiness", "teW", "stDev"])); %training dataset
kmedoidClustering = kmedoids(kmedoidTraining, 15); %apply k-medoids clustering

%% Plots
%check each cluster and assign it to a class
waveforms = table2array(trainingWaveforms(:,2));

x = linspace(0, 128, 128);
hold on

for i = 1:length(kmedoidClustering)
    if kmedoidClustering(i) == 1 %set cluster number from 1-15 here
       plot(x, waveforms(i, :), 'LineWidth', 3)
    else
    end
end
title('Cluster 1', 'FontSize', 30)
xlabel('Bin Number', 'FontSize', 30)
ylabel('Power(W)', 'FontSize', 30)
ax = gca;
ax.FontSize = 30;

hold off


%% KNN

%find KNN points for each test waveform
K = 15; %set K here
clusteredFeatures = table2array(trainingFeatures(:, 2:6));
queryFeatures = table2array(testFeatures(:,2:6)); %test set
kmedoidKNN = knnsearch(clusteredFeatures, queryFeatures, 'K', K); %find K nearest points in training set to each test point

%% KNN Classification

%assign each test waveform to closest cluster based on KNN, and classify
%accordingly
assignedClusters = zeros(1, length(kmedoidKNN));
assignedLabels = strings(1, length(kmedoidKNN));
clusters = zeros(1, K);
for i = 1:length(kmedoidKNN)
    KPoints = kmedoidKNN(i,:);
    clustervotes = strings(1, K);
    for j = 1:K
        clusters(j) = kmedoidClustering(KPoints(j));
        %set clusters manually labelled as leads here
        if clusters(j) == 2 || clusters(j) == 7 || clusters(j) == 9 || clusters(j) == 9 || clusters(j) == 13 || clusters(j) == 15
            clustervotes(j) = 'lead';
        else
            clustervotes(j) = 'ice';
        end
    end
    leadVotes = 0;
    for l = 1:K
        if clustervotes(l) == 'lead'
            leadVotes = leadVotes+1;
        else
        end
    end
    if leadVotes>K/2
        assignedLabels(i) = 'lead';
    else
        assignedLabels(i) = 'ice';
    end
end

%check accuracy, TLR, and FLR of classification
correctClassification = 0;
TrueIce = 0;
TrueLead = 0;
FalseIce = 0;
FalseLead = 0;
for i = 1:length(kmedoidKNN)
    if assignedLabels(i) == testLabels(i)
        correctClassification = correctClassification+1;
        if assignedLabels(i) == 'lead'
            TrueLead = TrueLead+1;
        else
            TrueIce = TrueIce+1;
        end
    else
        if assignedLabels(i) == 'lead'
            FalseLead = FalseLead+1;
        else
            FalseIce = FalseIce+1;
        end
    end
end

accuracy = (correctClassification/552)*100
TLR = (TrueLead/(TrueLead+FalseIce))*100
FLR = (FalseLead/(FalseLead+TrueIce))*100

%% SOM
trainingPredictors = (table2array(trainingFeatures(:, ["maxPower", "kurt", "pulsePeakiness", "teW", "stDev"]))); %training set
testPredictors = (table2array(testFeatures(:, ["maxPower", "kurt", "pulsePeakiness", "teW", "stDev"]))); %test set

%train SOM, and use generated plots to manually label neurons
net = selforgmap([10 10]);
[net, tr] = train(net, trainingPredictors');

%test SOM
y = net(testPredictors');
cluster_index = vec2ind(y);


%% SOM Classification

%set neurons labelled as leads
leadindices = [20 30 39 40 49 50 58 59 60 68 69 70 77 78 79 80 87 88 89 90 96 97 98 99 100];

%classify waveforms based on associated neuron
somclassification = strings(1, length(cluster_index));
for i = 1:length(cluster_index)
    if ismember(cluster_index(i), leadindices) == 1
        somclassification(i) = 'lead';
    else
        somclassification(i) = 'ice';
    end
end

%check accuracy, TLR, and FLR
correctClassification = 0;
TrueIce = 0;
TrueLead = 0;
FalseLead = 0;
FalseIce = 0;

for i = 1:length(somclassification)
    if somclassification(i) == testLabels(i)
        correctClassification = correctClassification+1;
        if somclassification(i) == 'ice'
            TrueIce = TrueIce+1;
        else
            TrueLead = TrueLead+1;
        end
    else
        if somclassification(i) == 'ice'
            FalseLead = FalseLead+1;
        else
            FalseIce = FalseIce+1;
        end
    end
end

accuracy = (correctClassification/552)*100
TLR = (TrueLead/(TrueLead+FalseIce))*100
FLR = (FalseLead/(FalseLead+TrueIce))*100