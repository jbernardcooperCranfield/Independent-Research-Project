ImageData = [table1; table2; table3; table4; table5; table6;];

labels = table2array(ImageData(:,1));

%initialise feature value arrays
maxPower = zeros(1, height(ImageData))';
kurt = table2array(ImageData(:,3));
skew = table2array(ImageData(:,5));
pulsePeakiness = zeros(1, height(ImageData))';
width = zeros(1, height(ImageData))';
leW = zeros(1, height(ImageData))';
teW = zeros(1, height(ImageData))';
ppL = zeros(1, height(ImageData))';
ppR = zeros(1, height(ImageData))';
ppLoc = zeros(1, height(ImageData))';
stDev = table2array(ImageData(:,4));
peakN = zeros(1, height(ImageData))';

for i = 1:height(ImageData)

    waveform = table2array(ImageData(i,2));
    [maximum, index] = max(waveform);
    
    %discard noisy measurements
    if index <= 20 || index >= 128-10
       labels(i) = 'Discarded';
       
       maxPower(i) = NaN;
       kurt(i) = NaN;
       skew(i) = NaN;
       pulsePeakiness(i) = NaN;
       waveformWidth(i) = NaN;
       leW(i) = NaN;
       teW(i) = NaN;
       ppL(i) = NaN;
       ppR(i) = NaN;
       ppLoc(i) = NaN;
       stDev(i) = NaN;
       peakNumberFeature(i) = NaN;
       peakN(i) = NaN;
       
        
    else
        
        %max power
        maxPower(i) = maximum;
        
        %pulse peakiness
        totalPower = sum(waveform);
        pulsePeakiness(i) = maximum/totalPower;
        
        
        %waveform width
        waveformWidth = 0;
        for k = 1:128
            if waveform(k) > 0.1*maximum
                waveformWidth = waveformWidth+1;
            else
            end
        end
        width(i) = waveformWidth;
        
        %leading-edge width
        leadingEdge = waveform(1:index);
        leadingEdgeDifference = leadingEdge-0.01*maximum;
        [~, minimumIndex] = min(abs(leadingEdgeDifference));
        leW(i) = index-minimumIndex;
        
        %trailing-edge width
        trailingEdge = waveform(index:length(waveform));
        trailingEdgeDifference = trailingEdge-0.01*maximum;
        [~, minimumIndex] = min(abs(trailingEdgeDifference));
        teW(i) = minimumIndex-index;
        
        %pulse peakiness left
        totalPowerLeft = waveform(index-3) + waveform(index-2) + waveform(index-1);
        ppL(i) = maximum/totalPowerLeft;
        
        %pulse peakiness right
        totalPowerRight = waveform(index+1)+waveform(index+2)+waveform(index+3);
        ppR(i) = maximum/totalPowerRight;
        
        %pulse peakiness local
        ppLoc(i) = maximum/(totalPowerLeft+totalPowerRight);
        
        
        %peak number
        peaks2 = findpeaks(waveform, 'MinPeakProminence', 0.01);
        peakN(i) = length(peaks2);
    end
end

Features = table(labels, maxPower, kurt,...
    skew, pulsePeakiness,...
    width,...
    leW, teW,...
    ppL, ppR,...
    ppLoc, stDev,...
    peakN, 'VariableNames', {'labels', 'maxPower', 'kurt','skew', 'pulsePeakiness',...
    'waveformWidth', 'leW', 'teW', 'ppL', 'ppR', 'ppLoc', 'stDev', 'peakN'});


