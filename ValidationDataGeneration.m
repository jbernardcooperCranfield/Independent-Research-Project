clear all
close all

%% load in Sentinel-3 data and preprocess

%SRAL waveforms
SRALWaveformsAll = ncread('measurement_l1bs.nc', 'i2q2_meas_ku_l1bs_echo_sar_ku');

%SRAL metadata
SRALLat = ncread('measurement_l1bs.nc', 'lat_l1bs_echo_sar_ku');
SRALLon = ncread('measurement_l1bs.nc', 'lon_l1bs_echo_sar_ku');
SRALTime = ncread('measurement_l1bs.nc', 'time_l1bs_echo_sar_ku');

%Values of kurt, SSD, skew, and sigma0
kurtValues = ncread('measurement_l1bs.nc', 'kurt_stack_l1bs_echo_sar_ku');
stDevValues = ncread('measurement_l1bs.nc', 'stdev_stack_l1bs_echo_sar_ku');
skewValues = ncread('measurement_l1bs.nc', 'skew_stack_l1bs_echo_sar_ku');
sigma0Values = ncread('measurement_l1bs.nc', 'sig0_cal_ku_l1bs_echo_sar_ku');

%OLCI metadata
OLCILat = ncread('geo_coordinates.nc', 'latitude'); %OLCI latitude values
OLCILon = ncread('geo_coordinates.nc', 'longitude'); %OLCI longitude values

%correct OLCI longitude to be same coordinates as SRAL longitude
OLCILonFixed = zeros(4865, 4091); 
for i = 1:4865
    for j = 1:length(OLCILon(1,:))
        OLCILonValue = OLCILon(i, j);
        if OLCILonValue<0
            OLCILonFixed(i, j) = OLCILonValue+360;
        else
            OLCILonFixed(i, j) = OLCILonValue;
        end
    end
end


OLCITimeRaw = ncread('time_coordinates.nc', 'time_stamp');%OLCI time values
OLCITimeOffset = OLCITimeRaw/1000000; %make same units as SRAL time values
OLCITime = OLCITimeOffset-18.021514892578125; %correct for offset with SRAL data
startTime = OLCITime(1); %start time of OLCI image
endTime = OLCITime(length(OLCITime)); %end time of OLCI image

%% Segment SRAL data to be only the waveforms overlapping with the OLCI image

%calculate the time differences between each SRAL waveform and the time of
%the first OLCI row
startTimeDiff = zeros(1, length(SRALTime));
for i = 1:length(SRALTime)
    startTimeDiff(i) = abs(SRALTime(i)-startTime);
end

%calculate the time differences between each SRAL waveform and the time of the last OLCI row
endTimeDiff = zeros(1, length(SRALTime));
for i = 1:length(SRALTime)
    endTimeDiff(i) = abs(SRALTime(i)-endTime);
end

%find the SRAL waveform most closely aligned in time with the first row of the OLCI image
[startMinDiff, startMinIndex] = min(startTimeDiff);
SRALStartIndex = startMinIndex;

%find the SRAL waveform most closely aligned in time with the last row of the OLCI image
[endMinDiff, endMinIndex] = min(endTimeDiff);
SRALEndIndex = endMinIndex;

%segment the SRAL waveforms and the SRAL metadata
SRALWaveforms(:,:) = (SRALWaveformsAll(:,SRALStartIndex:SRALEndIndex))'; % array of waveforms overlapping the OLCI image
SRALWaveformsTime = SRALTime(SRALStartIndex:SRALEndIndex); %time values of waveforms overlapping the OLCI image
SRALWaveformsTimeLocal = SRALWaveformsTime-OLCITime(1); %time of each waveform relative to the first row of the OLCI image
SRALWaveformsLat = SRALLat(SRALStartIndex:SRALEndIndex); %latitude values of waveforms overlapping the OLCI image
SRALWaveformsLon = SRALLon(SRALStartIndex:SRALEndIndex); %longitude values of waveforms overlapping the OLCI image

kurtValues = kurtValues(SRALStartIndex:SRALEndIndex); %kurt values of waveforms overlapping the OLCI image
stDevValues = stDevValues(SRALStartIndex:SRALEndIndex); %SSD values of waveforms overlapping the OLCI image
skewValues = skewValues(SRALStartIndex:SRALEndIndex); %skew values of waveforms overlapping the OLCI image
sigma0Values = sigma0Values(SRALStartIndex:SRALEndIndex); %sigma0 values of waveforms overlapping the OLCI image

%% Define the individual scene and its metadata

%define the bounds of the scene within the OLCI image
sceneWidth = 30; %width of the scene about the ground track
groundTrackBin = 3617; %ground track shown to be at 3617th bin

XStartScene = groundTrackBin-sceneWidth; %X index of scene start
XEndScene = groundTrackBin+sceneWidth; %X index of scene end
YStartScene = 1800; %Y index of scene start
YEndScene = 2100; %Y index of scene end

sceneStartTime = OLCITime(YStartScene); %Scene start time
sceneEndTime = OLCITime(YEndScene); %Scene end time

%segment metadata for the scene
OLCILatScene = OLCILat(XStartScene:XEndScene, YStartScene:YEndScene);
OLCILonScene = OLCILonFixed(XStartScene:XEndScene, YStartScene:YEndScene);

%calculate the time differences between each SRAL waveform and the start time of the scene
sceneStartTimeDiff = zeros(1, length(SRALWaveformsTime));
for i = 1:length(SRALWaveformsTime)
    sceneStartTimeDiff(i) = abs(SRALWaveformsTime(i)-sceneStartTime);
end

%find the SRAL waveform most closely aligned in time with the first row of
%the scene
[~, sceneStartSRAL] = min(sceneStartTimeDiff);

%calculate the time differences between each SRAL waveform and the end 
%time of the scene
sceneEndTimeDiff = zeros(1, length(SRALWaveformsTime));
for i = 1:length(SRALWaveformsTime)
    sceneEndTimeDiff(i) = abs(SRALWaveformsTime(i)-sceneEndTime);
end

%find the SRAL waveform most closely aligned in time with the last row of
%the scene
[~, sceneEndSRAL] = min(sceneEndTimeDiff);
SRALWaveformsScene = SRALWaveforms(sceneStartSRAL:sceneEndSRAL,:); %SRAL waveforms overlapping the scene
SRALTimeScene = SRALWaveformsTime(sceneStartSRAL:sceneEndSRAL); %time values of waveforms overlapping the scene
SRALTimeLocalScene = SRALTimeScene-sceneStartTime; %time of each waveform relative to the first row of the scene
SRALLatScene = SRALWaveformsLat(sceneStartSRAL:sceneEndSRAL); %latitude values of waveforms overlapping the scene
SRALLonScene = SRALWaveformsLon(sceneStartSRAL:sceneEndSRAL); %longitude values of waveforms overlapping the scene

kurtScene = kurtValues(sceneStartSRAL:sceneEndSRAL); %kurt values of waveforms overlapping the scene
stDevScene = stDevValues(sceneStartSRAL:sceneEndSRAL); %SSD values of waveforms overlapping the scene
skewScene = skewValues(sceneStartSRAL:sceneEndSRAL); %skew values of waveforms overlapping the scene
sigma0Scene = sigma0Values(sceneStartSRAL:sceneEndSRAL); %sigma0 values of waveforms overlapping the scene


%% Find pixels most closely aligned to each SRAL waveform overlapping the scene

%find three pixels most closely aligned with each waveform, excluding
%waveforms where the most closely aligned pixel is not within a specified
%absolute distance
columnPixel1 = zeros(1, length(SRALTimeLocalScene));
rowPixel1 = zeros(1, length(SRALTimeLocalScene));
columnPixel2 = zeros(1, length(SRALTimeLocalScene));
rowPixel2 = zeros(1, length(SRALTimeLocalScene));
columnPixel3 = zeros(1, length(SRALTimeLocalScene));
rowPixel3 = zeros(1, length(SRALTimeLocalScene));

for i = 1:length(SRALTimeLocalScene)
    Lat = SRALLatScene(i);
    Lon = SRALLonScene(i);
    LatDiffMatrix = OLCILatScene-Lat;
    LonDiffMatrix = OLCILonScene-Lon;
    TotalDiffMatrix = abs(LatDiffMatrix)+abs(LonDiffMatrix);
    [minCol, minRow] = find(TotalDiffMatrix==min(min(TotalDiffMatrix)));

    if TotalDiffMatrix(minCol, minRow)>=0.00239
        columnPixel1(i) = NaN;
        rowPixel1(i) = NaN;
        columnPixel2(i) = NaN;
        rowPixel2(i) = NaN;
        columnPixel3(i) = NaN;
        rowPixel3(i) = NaN;
    else
        columnPixel1(i) = minCol;
        rowPixel1(i) = minRow;

        TotalDiffMatrix(minCol, minRow) = 999;
        [minCol, minRow] = find(TotalDiffMatrix==min(min(TotalDiffMatrix)));
        columnPixel2(i) = minCol;
        rowPixel2(i) = minRow;

        TotalDiffMatrix(minCol, minRow) = 999;
        [minCol, minRow] = find(TotalDiffMatrix==min(min(TotalDiffMatrix)));
        columnPixel3(i) = minCol;
        rowPixel3(i) = minRow;
    end
end


%% Determine classification of waveform by majority vote of pixels and radiance value

%load k-means clustering of the scene from SNAP
classIndices = ncread('1800-2100.nc', 'class_indices');

%majority vote to classify each pixel based on k-means clustering
classes = strings(1, length(SRALWaveformsScene));
for i = 1:length(SRALWaveformsScene)
    if isnan(rowPixel1(i)) == 1 || rowPixel1(i) > length(classIndices)
        classes(i) = 'NaN';
    else
        vote1 = classIndices(columnPixel1(i), rowPixel1(i));
        vote2 = classIndices(columnPixel2(i), rowPixel2(i));
        vote3 = classIndices(columnPixel3(i), rowPixel3(i));
        if vote1+vote2+vote3<=1
            classes(i) = 'ice';
        else
            classes(i) = 'lead';
        end
    end
end

%load Oa03 radiance along ground track for scene and set threshold
Oa03 = (ncread('Oa03_radiance.nc','Oa03_radiance'));
Oa03Scene = Oa03(XStartScene:XEndScene, YStartScene:YEndScene);
Oa03Nadir = Oa03Scene(sceneWidth+1,:);
peakRadiance = max(Oa03Nadir);
radianceThreshold = 0.95*peakRadiance;

%classify pixels along ground track based on Oa03 radiance value
classes2 = strings(1, length(Oa03Nadir));
[troughs, troughlocs, troughwidths] = findpeaks(-Oa03Nadir);
for i = 1:length(troughs)
    if abs(troughs(i)) <= radianceThreshold
        classes2(round(troughlocs(i)-troughwidths(i)):round(troughlocs(i)+troughwidths(i))) = 'lead';
    else
        if round(troughlocs(i)-troughwidths(i)) ~= 0
            classes2(round(troughlocs(i)-troughwidths(i)):round(troughlocs(i)+troughwidths(i))) = 'ice';
        else
            classes2(round(troughlocs(i)-troughwidths(i))+1:round(troughlocs(i)+troughwidths(i))) = 'ice';
        end
    end
end

%compare classification from k-means clustering and radiance check, and
%classify waveforms where both classifications agree
classesFinal = strings(1, length(SRALWaveformsScene));
for i = 1:length(SRALWaveformsScene)
    if isnan(rowPixel1(i)) == 1
        classesFinal(i) = 'discarded';
    else
        if classes(i) == classes2(rowPixel1(i))
            classesFinal(i) = classes(i);
        else
            classesFinal(i) = 'discarded';
        end
    end
end


%% Tabulate waveforms, extracted feature values, and classes and save

tableLength = sum(classesFinal~='discarded');
WaveformClasses = strings(1, tableLength);
Waveforms = zeros(128, tableLength)';

kurt = zeros(1, tableLength)';
stDev = zeros(1, tableLength)';
skew = zeros(1, tableLength)';
sigma0 = zeros(1, tableLength)';

counter = 0;
for i = 1:length(SRALWaveformsScene)
    if classesFinal(i) ~= 'discarded'
        counter = counter+1;
        WaveformClasses(counter) = classesFinal(i);
        Waveforms(counter, :) = SRALWaveformsScene(i,:);

        kurt(counter) = kurtScene(i);
        stDev(counter) = stDevScene(i);
        skew(counter) = skewScene(i);
        sigma0(counter) = sigma0Scene(i);
    else
    end
end

LabeledWaveforms = table(WaveformClasses', Waveforms, kurt, stDev, skew, sigma0);

