%Code By: Mahesh Shrestha
%Data : April 10, 2016

%Objective: To perform Cross Calibration of Landsat 8 and Sentinal 2
    %First Step: Find the simultaneous pair of scene and ROI
    %Second Step: Correct the data (SBAF and solar zenith)
    %Third Step: Compare the reflectance value of Landsat 8 and Sentinal2
   
clc
clear all
%ImageDrive = '/Users/maheshshrestha/Desktop/CrossCalibrationLandsat8Sentinal2/Image/';
ImageDrive = 'Z:\SpecialNeeds\Mahesh\CrossCalibrationLandsat8Sentinal2\Image';
ListOfFolder = ls(ImageDrive);

%ImageLocation = ListOfFolder(1,1:40)
ListOfFolder(1:10,:) = [];
%for i = 1 : 3
%Extract the information from Landsat8
    ImageLocation = fullfile(ImageDrive,ListOfFolder(2,:))

    ListOfImage = ls(strcat(ImageLocation,'\'));
    ListOfImage(1:16,:) = [];

    %ImageIndices
    ImageIndexLandsat = [2 6 8 10 12 14 16 ];
    %ImageIndexLandsat = [2 6 7 8 9 10 11];
    L8SolarZenith = 90 - 24.95;

    %full location of the image name
    for j = 1 : size(ImageIndexLandsat,2)

        ImageFile = strcat(ImageLocation,'\',ListOfImage(ImageIndexLandsat(j),:))
        [ImageIn,R,bbox] = geotiffread(ImageFile);
        ImageInfo = geotiffinfo(ImageFile);

        %find out the size of an image
        [Row, Column] = size(ImageIn);

        %Latitude and Longitude of Lake Tahoe
        %{
        LongitudeUL = 750655.9058;   LatitudeUL = 4338327.2754;
        LongitudeUR = 762126.8115;   LatitudeUR = 4338327.2754;
        LongitudeLR = 762126.8115;   LatitudeLR = 4327493.6353;
        LongitudeLL = 750655.9058;   LatitudeLL = 4327493.6353;
        %}
        
        %converting map values of ROI to the pixel location
        %{
        [UL_Row, UL_Column] = map2pix(R,  LongitudeUL, LatitudeUL);
        [UR_Row, UR_Column] = map2pix(R,  LongitudeUR, LatitudeUR);
        [LR_Row, LR_Column] = map2pix(R,  LongitudeLR, LatitudeLR);
        [LL_Row, LL_Column] = map2pix(R,  LongitudeLL, LatitudeLL);
        %}
        
        %Map value of the center pixels
        %Landsat 8
        LongitudeCoastalL8 = 755604.9553;  LatitudeCoastalL8 = 4333777.0423;
        
        %Sentinal 2A
        %LongitudeCoastalS2A = 236743.1844;  LatitudeCoastalS2A = 4332526.4405;
        
        %Convert Map values to the pixel location
        [CenterRow, CenterColumn] = map2pix(R, LongitudeCoastalL8 , LatitudeCoastalL8);
        
        %check the value of the center pixel
        ImageIn(floor(CenterRow),floor(CenterColumn));
        
        %ROI Width
        ROIWidth = 100;
        %construct the ROI around the center pixel
        LowerRow = CenterRow - ROIWidth;
        UpperRow = CenterRow + ROIWidth;
        LowerColumn = CenterColumn - ROIWidth;
        UpperColumn = CenterColumn + ROIWidth;
        
        UL_Row = UpperRow; UL_Column = LowerColumn;
        UR_Row = UpperRow; UR_Column = UpperColumn;
        LR_Row = LowerRow; LR_Column = UpperColumn;
        LL_Row = LowerRow; LL_Column = LowerColumn;


        ROIRow = [UL_Row UR_Row LR_Row LL_Row UL_Row];
        ROIColumn = [UL_Column UR_Column LR_Column LL_Column UL_Column];
        
        CroppedImageInLandsat8(:,:) = ImageIn( LowerRow:UpperRow,...
                                                    LowerColumn:UpperColumn);
        %figure('Color',[1 1 1])
        %imagesc(CroppedImageInLandsat8)
        %xlabel('Pixel','Fontsize',24,'FontName','Times New Roman');
        %ylabel('Pixel','Fontsize',24,'FontName','Times New Roman');
        %title('ROI SWIR2 band Landsat8','Fontsize',30,'FontName','Times New Roman');
        %colorbar
        %mask the ROI
        MaskedROI = poly2mask(ROIColumn,ROIRow,Row,Column);
        
        %figure()
        %imagesc(MaskedROI)
        
        ImageIn(~MaskedROI) = false;
        MaskedImage = ImageIn(ImageIn~=0);
        
        %figure()
        %imagesc(MaskedROI)
        
        MeanROI = mean(MaskedImage);

        %multiplicative factor for finding reflelctance 
        BandMulFactor = 2*10^-5;

        %additive factor for finding reflelctance 
        BandAddFactor = -0.1;

        %reflectance of ROI
        %ToaReflectance(j) = BandMulFactor * MeanROI + BandAddFactor
        TOADNL8(1,j) = MeanROI;
        
        MeanROI = (BandMulFactor * MeanROI + BandAddFactor)/cosd(L8SolarZenith);
        
        TOAReflectanceL8(1,j) = MeanROI;
    end
%end


%Extract the information from Sentinal2A

 ImageLocation = fullfile(ImageDrive,ListOfFolder(3,:))
 ListOfFolderS2A1 = ls(strcat(ImageLocation,'\'))
 ListOfFolderS2A1(1:10,:) = []
 
 ImageLocation = strcat(ImageLocation,'\',ListOfFolderS2A1(4,:))
 ListOfFolderS2A2 = ls(strcat(ImageLocation,'\'))
  
 ListOfFolderS2A2(1:5,:)=[]
 
 ImageLocation = strcat(ImageLocation,'\',ListOfFolderS2A2(1,:))
 ListOfFolderS2A3 = ls(strcat(ImageLocation,'\'))
 ListOfFolderS2A3(1:8,:) = []
 
 ImageLocation = strcat(ImageLocation,'\',ListOfFolderS2A3(2,:))
 ListOfImageS2A = ls(strcat(ImageLocation,'\'))
 
 ListOfImageS2A(1:16,:) = []
 
 %select images only from seven bands
 ImageIndexSentinal2A = [1 2 3 4 13 11 12];
 
 for j = 1 : size(ImageIndexSentinal2A,2)
 
     ImageFile = strcat(ImageLocation,'\',ListOfImageS2A(ImageIndexSentinal2A(j),:))

     ImageInSentinal2A = double(imread(ImageFile));
     [Row,Column] = size(ImageInSentinal2A);
     %Sentinal 2A


      %Convert Map values to the pixel location
      %[CenterRow, CenterColumn] = map2pix(R, LongitudeCoastalS2A, LatitudeCoastalS2A);
      if (j ==1)
        
        CenterRow = 1100
        CenterColumn = 614
      
      elseif(j == 2 || j == 3 || j== 4)
          
        CenterRow = 6600
        CenterColumn = 3684
        
      else
        
        CenterRow = 3300
        CenterColumn = 1842
            
      end
      %ROI Width
      ROIWidth = 100;
      %construct the ROI around the center pixel
      LowerRow = CenterRow - ROIWidth;
      UpperRow = CenterRow + ROIWidth;
      LowerColumn = CenterColumn - ROIWidth;
      UpperColumn = CenterColumn + ROIWidth;

      UL_Row = UpperRow; UL_Column = LowerColumn;
      UR_Row = UpperRow; UR_Column = UpperColumn;
      LR_Row = LowerRow; LR_Column = UpperColumn;
      LL_Row = LowerRow; LL_Column = LowerColumn;


      ROIRow = [UL_Row UR_Row LR_Row LL_Row UL_Row];
      ROIColumn = [UL_Column UR_Column LR_Column LL_Column UL_Column];

      CroppedImageInSentinal2A(:,:) = ImageInSentinal2A( LowerRow:UpperRow,...
                                                    LowerColumn:UpperColumn);
      %figure('Color',[1 1 1])
      %imagesc( CroppedImageInSentinal2A)  
      %mask the ROI
      MaskedROI = poly2mask(ROIColumn,ROIRow,Row,Column);
      
      %figure()
      %imagesc( CroppedImageInSentinal2A)   
      
      %mean2(CroppedImageInSentinal2A)

      ImageInSentinal2A(~MaskedROI) = false;
      MaskedImage = ImageInSentinal2A(ImageInSentinal2A~=0);
      
      %DN of sentinal should be divided by 10000 to convert into
      %reflectance
      
      MeanROI = mean(MaskedImage);
      TOADNSentinal(1,j) = MeanROI;
      MeanROI = (mean(MaskedImage))/10000;
      TOAReflectanceSentinal(1,j) = MeanROI;
      
 end
 
figure('Color',[1 1 1]) 
plot(TOADNL8(1,:),'r*'); hold on
plot(TOADNSentinal,'b*'); grid on

%plot(TOAReflectanceL8(1,:),'r*'); hold on
%plot(TOAReflectanceSentinal,'b*'); grid on

figure('Color',[1 1 1])
plot(TOAReflectanceL8(1,:),'Color',[1 0 0],'MarkerFaceColor',[1 0 0],...
         'Marker','hexagram','MarkerSize',14,'Linestyle','None'); hold on
plot(TOAReflectanceSentinal(1,:),'Color',[0 1 0],'MarkerFaceColor',[0 1 0],...
         'Marker','o','MarkerSize',14,'Linestyle','None'); grid on
xlabel('Band','Fontsize',20,'FontName','Times New Roman');
ylabel('Reflectance','Fontsize',20,'FontName','Times New Roman');
title('Comparison of TOA reflectace of L8 and S2A over lake Tahoe','Fontsize',24,'FontName','Times New Roman');
legend('TOA reflectance of Landsat8 ','TOA reflectance of Sentinal2A')

save('TOAReflectanceL8.mat','TOAReflectanceL8');
save('TOAReflectanceSentinal.mat','TOAReflectanceSentinal');


%calculate SBAF
%Map values and pixel location of ROI

%Map values
% UL_Row = 746365.2142; UL_Column = 4336314.9429;
% UR_Row = 749605.3158; UR_Column = 4336314.9429;
% LR_Row = 749605.3158; LR_Column = 4333925.6434;
% LL_Row = 746365.2142; LL_Column = 4334096.3074;

%Pixel Location
 UL_Row = 529; UL_Column = 1146;
 UR_Row = 637; UR_Column = 1146;
 LR_Row = 637; LR_Column = 1226;
 LL_Row = 529; LL_Column = 1226;

%HyperionWavelength
HyperionWavelength = [355.6	365.8	375.9	386.1	396.3	406.5	416.6	426.8	437	447.2	457.3	467.5	477.7	487.9	498	508.2	518.4	528.6	538.7	548.9	559.1	569.3	579.5	589.6	599.8	610	620.1	630.3	640.5	650.7	660.9	671	681.2	691.4	701.6	711.7	721.9	732.1	742.2	752.4	762.6	772.8	783	793.1	803.3	813.5	823.6	833.8	844	854.2	864.4	874.5	884.7	894.9	905	915.2	925.4	935.6	945.8	955.9	966.1	976.3	986.5	996.6	1006.8	1016.9	1027.1	1037.3	1047.5	1057.6	851.9	862	872.1	882.2	892.3	902.4	912.5	922.5	932.6	942.7	952.8	962.9	973	983.1	993.2	1003.3	1013.3	1023.4	1033.4	1043.5	1053.6	1063.7	1073.8	1083.9	1094	1104.1	1114.1	1124.2	1134.3	1144	1154	1164	1174	1184	1194	1205	1215	1225	1235	1245	1255	1265	1275	1285	1295	1305	1316	1326	1336	1346	1356	1366	1376	1386	1396	1406	1416	1426	1437	1447	1457	1467	1477	1487	1497	1507	1517	1527	1537	1548	1558	1568	1578	1588	1598	1608	1618	1628	1638	1648	1659	1669	1679	1689	1699	1709	1719	1729	1739	1749	1759	1769	1780	1790	1800	1810	1820	1830	1840	1850	1860	1870	1880	1891	1901	1911	1921	1931	1941	1951	1961	1971	1981	1991	2002	2012	2022	2032	2042	2052	2062	2072	2082	2092	2102	2113	2123	2133	2143	2153	2163	2173	2183	2193	2203	2213	2224	2234	2244	2254	2264	2274	2284	2294	2304	2314	2324	2335	2345	2355	2365	2375	2385	2395	2405	2415	2425	2435	2445	2456	2466	2476	2486	2496	2506	2516	2526	2536	2546	2556	2566	2577];

%esun_chkkur = esun_chkkur';
EsunChkkur= [989.151260979967,1100.38452348877,1096.10257547731,1026.54726596085,1241.02854639893,1658.57623854906,1724.74200023805,1643.20749786447,1740.79153110847,1966.17585008161,2037.54108860649,2004.42244916477,2015.33286645278,1928.45814221228,1933.40027517799,1915.65764064636,1830.65563985097,1883.64200775510,1875.98500936982,1872.42022921987,1843.77894412643,1845.39631915465,1843.21949117138,1791.31437361641,1763.10662235426,1733.15873097577,1703.57283970204,1669.98982713895,1631.41087745291,1574.54750536936,1537.62351209878,1523.45624421287,1472.64900993724,1447.52648218385,1397.28915192593,1359.62568638637,1263.92998445989,1273.65058458529,1283.29317618479,1268.51946998063,1231.76004141456,1202.21015482730,1190.13594689273,1151.96695727404,1127.86481368520,1100.05858868362,1068.92872501720,1045.31602866368,1015.00382902581,968.967428803187,962.652514987262,958.138871595595,951.044382158845,944.035490481621,944.599451436531,933.573607680206,929.636959117116,919.365387022998,913.523195532930,893.950133349241,888.681720776609,875.966356754142,869.828818651036,847.659509476404,843.201004786796,838.307724897535,832.338270376783,815.106383526864,811.160631316107,799.615139345190,793.688048366651,784.083728833427,779.837663618075,770.635545774930,765.956333724978,756.788753461124,751.879065443263,743.076566429957,737.899651701295,723.364636606415,717.782977983634,711.223566712783,705.813698774079,697.914547351582,693.425378420286,683.013601155712,677.009367924329,668.547713175749,663.650954881556,655.472709514752,648.751316766325,637.875369505623,621.114653453370,605.722918669567,586.544232661370,580.936495031034,572.399868156559,560.234078167448,549.098017610992,540.259122357785,532.369524379341,519.040893740004,510.644392547267,499.256687717946,490.212163287535,479.649942238531,476.444303021319,469.187793010313,460.719259390384,452.046523595025,443.899531780067,435.504683100613,425.301569443860,412.658063021669,413.115514080344,405.596391784153,397.038235801313,391.616676801107,385.096327655793,379.445653765322,371.589977367949,365.030212189313,359.332326540043,354.465052506516,348.215843243201,341.173979420105,334.410093690011,326.578670393909,322.800288183179,316.718895634221,312.198566011947,306.976226551834,300.732942258246,295.469725364071,291.765380971536,284.702193571895,284.492170484983,280.307441921457,275.977456450957,271.505268854249,266.297262420847,260.795502581386,253.177229629077,247.412768771386,247.711271954570,242.705808109096,238.672148934704,237.889454883784,228.453738824804,226.444444677814,224.918001589816,218.702763168607,210.177598036952,209.618301381587,206.996260507730,201.605576626443,197.645974154035,190.640907605934,185.030663228252,185.216544109476,182.796866803949,179.563772742611,175.555052429153,172.897595513899,169.004167382356,164.260342661482,157.810518213155,158.655262399913,155.298565393657,152.506042769071,148.994318705402,142.071306851262,140.060306640159,139.408837971981,137.951483561310,136.528547492667,133.806446133052,130.243322259283,124.873103367908,124.010254872309,123.971399992255,121.575356144027,119.252068342572,117.615041550114,115.809633458542,114.306185802170,111.627796948816,109.258561308342,107.845044718070,106.122580035074,103.712267153081,102.314003328878,100.434079322950,98.3370632889330,97.2096638852763,95.4812110774562,93.6018691070513,92.3684816430653,90.8835047267369,89.2338496085502,85.1685076880038,84.8985215839029,84.3686591888557,83.4399625610181,81.7345895091801,80.5607001542873,79.3706092175511,78.1013363977367,76.6909709727789,75.3215713214195,74.1327708570375,73.1046052211668,71.6377404653969,70.1820610709732,69.4270906325417,68.2350581843695,66.4577573614202,65.7706928537004,65.0361360962252,63.2773030207199,62.8062113689411,61.6260330040805,60.1081549267947,59.8565613168343,59.1068616934759,57.4519899418985,57.0279078546179,56.2430099170395,55.1049784528987,54.0863413454609,53.7238026844068,52.6811252400229,51.6956539470925,51.4233781371653,50.6460875620672,49.8296870521201,49.3585037795306,48.4160115844206,47.6066666506727,46.9430045042601,46.3528764740439,45.8148041456104];

% Earth sun distance
SunDistance = [0.983310000000000;0.983300000000000;0.983300000000000;0.983300000000000;0.983300000000000;0.983320000000000;0.983330000000000;0.983350000000000;0.983380000000000;0.983410000000000;0.983450000000000;0.983490000000000;0.983540000000000;0.983590000000000;0.983650000000000;0.983710000000000;0.983780000000000;0.983850000000000;0.983930000000000;0.984010000000000;0.984100000000000;0.984190000000000;0.984280000000000;0.984390000000000;0.984490000000000;0.984600000000000;0.984720000000000;0.984840000000000;0.984960000000000;0.985090000000000;0.985230000000000;0.985360000000000;0.985510000000000;0.985650000000000;0.985800000000000;0.985960000000000;0.986120000000000;0.986280000000000;0.986450000000000;0.986620000000000;0.986800000000000;0.986980000000000;0.987170000000000;0.987350000000000;0.987550000000000;0.987740000000000;0.987940000000000;0.988140000000000;0.988350000000000;0.988560000000000;0.988770000000000;0.988990000000000;0.989210000000000;0.989440000000000;0.989660000000000;0.989890000000000;0.990120000000000;0.990360000000000;0.990600000000000;0.990840000000000;0.991080000000000;0.991330000000000;0.991580000000000;0.991830000000000;0.992080000000000;0.992340000000000;0.992600000000000;0.992860000000000;0.993120000000000;0.993390000000000;0.993650000000000;0.993920000000000;0.994190000000000;0.994460000000000;0.994740000000000;0.995010000000000;0.995290000000000;0.995560000000000;0.995840000000000;0.996120000000000;0.996400000000000;0.996690000000000;0.996970000000000;0.997250000000000;0.997540000000000;0.997820000000000;0.998110000000000;0.998400000000000;0.998680000000000;0.998970000000000;0.999260000000000;0.999540000000000;0.999830000000000;1.00012000000000;1.00041000000000;1.00069000000000;1.00098000000000;1.00127000000000;1.00155000000000;1.00184000000000;1.00212000000000;1.00240000000000;1.00269000000000;1.00297000000000;1.00325000000000;1.00353000000000;1.00381000000000;1.00409000000000;1.00437000000000;1.00464000000000;1.00492000000000;1.00519000000000;1.00546000000000;1.00573000000000;1.00600000000000;1.00626000000000;1.00653000000000;1.00679000000000;1.00705000000000;1.00731000000000;1.00756000000000;1.00781000000000;1.00806000000000;1.00831000000000;1.00856000000000;1.00880000000000;1.00904000000000;1.00928000000000;1.00952000000000;1.00975000000000;1.00998000000000;1.01020000000000;1.01043000000000;1.01065000000000;1.01087000000000;1.01108000000000;1.01129000000000;1.01150000000000;1.01170000000000;1.01191000000000;1.01210000000000;1.01230000000000;1.01249000000000;1.01267000000000;1.01286000000000;1.01304000000000;1.01321000000000;1.01338000000000;1.01355000000000;1.01371000000000;1.01387000000000;1.01403000000000;1.01418000000000;1.01433000000000;1.01447000000000;1.01461000000000;1.01475000000000;1.01488000000000;1.01500000000000;1.01513000000000;1.01524000000000;1.01536000000000;1.01547000000000;1.01557000000000;1.01567000000000;1.01577000000000;1.01586000000000;1.01595000000000;1.01603000000000;1.01610000000000;1.01618000000000;1.01625000000000;1.01631000000000;1.01637000000000;1.01642000000000;1.01647000000000;1.01652000000000;1.01656000000000;1.01659000000000;1.01662000000000;1.01665000000000;1.01667000000000;1.01668000000000;1.01670000000000;1.01670000000000;1.01670000000000;1.01670000000000;1.01669000000000;1.01668000000000;1.01666000000000;1.01664000000000;1.01661000000000;1.01658000000000;1.01655000000000;1.01650000000000;1.01646000000000;1.01641000000000;1.01635000000000;1.01629000000000;1.01623000000000;1.01616000000000;1.01609000000000;1.01601000000000;1.01592000000000;1.01584000000000;1.01575000000000;1.01565000000000;1.01555000000000;1.01544000000000;1.01533000000000;1.01522000000000;1.01510000000000;1.01497000000000;1.01485000000000;1.01471000000000;1.01458000000000;1.01444000000000;1.01429000000000;1.01414000000000;1.01399000000000;1.01383000000000;1.01367000000000;1.01351000000000;1.01334000000000;1.01317000000000;1.01299000000000;1.01281000000000;1.01263000000000;1.01244000000000;1.01223000000000;1.01205000000000;1.01186000000000;1.01165000000000;1.01145000000000;1.01124000000000;1.01103000000000;1.01081000000000;1.01060000000000;1.01037000000000;1.01015000000000;1.00992000000000;1.00969000000000;1.00946000000000;1.00922000000000;1.00898000000000;1.00874000000000;1.00850000000000;1.00825000000000;1.00800000000000;1.00775000000000;1.00750000000000;1.00724000000000;1.00698000000000;1.00672000000000;1.00646000000000;1.00620000000000;1.00593000000000;1.00566000000000;1.00539000000000;1.00512000000000;1.00485000000000;1.00457000000000;1.00430000000000;1.00402000000000;1.00374000000000;1.00346000000000;1.00318000000000;1.00290000000000;1.00262000000000;1.00234000000000;1.00205000000000;1.00177000000000;1.00148000000000;1.00119000000000;1.00091000000000;1.00062000000000;1.00033000000000;1.00005000000000;0.999760000000000;0.999470000000000;0.999180000000000;0.998900000000000;0.998610000000000;0.998320000000000;0.998040000000000;0.997750000000000;0.997470000000000;0.997180000000000;0.996900000000000;0.996620000000000;0.996340000000000;0.996050000000000;0.995770000000000;0.995500000000000;0.995220000000000;0.994940000000000;0.994670000000000;0.994400000000000;0.994120000000000;0.993850000000000;0.993590000000000;0.993320000000000;0.993060000000000;0.992790000000000;0.992530000000000;0.992280000000000;0.992020000000000;0.991770000000000;0.991520000000000;0.991270000000000;0.991020000000000;0.990780000000000;0.990540000000000;0.990300000000000;0.990070000000000;0.989830000000000;0.989610000000000;0.989380000000000;0.989160000000000;0.988940000000000;0.988720000000000;0.988510000000000;0.988300000000000;0.988090000000000;0.987890000000000;0.987690000000000;0.987500000000000;0.987310000000000;0.987120000000000;0.986940000000000;0.986760000000000;0.986580000000000;0.986410000000000;0.986240000000000;0.986080000000000;0.985920000000000;0.985770000000000;0.985620000000000;0.985470000000000;0.985330000000000;0.985190000000000;0.985060000000000;0.984930000000000;0.984810000000000;0.984690000000000;0.984570000000000;0.984460000000000;0.984360000000000;0.984260000000000;0.984160000000000;0.984070000000000;0.983990000000000;0.983910000000000;0.983830000000000;0.983760000000000;0.983700000000000;0.983630000000000;0.983580000000000;0.983530000000000;0.983480000000000;0.983440000000000;0.983400000000000;0.983370000000000;0.983350000000000;0.983330000000000;0.983310000000000];


ImageLocationHyperion = strcat(ImageDrive,'\',ListOfFolder(1,:));

ListOfImageHyperion = ls(ImageLocationHyperion);
ListOfImageHyperion(1:2,:) = [];

ImageId = ListOfImageHyperion(1,:);
BaseName = ImageId(1,1:22);

%read the meta data file of an image
HyperionMetaDataFileName =  strcat(ImageLocationHyperion,'\',BaseName,'_','MTL_L1T.TXT');

HyperionMetaData = MTL_parser_hyperion(HyperionMetaDataFileName);
HyperionAcquisitionData = HyperionMetaData.PRODUCT_METADATA.ACQUISITION_DATE;
[doy,fraction] = date2doy(datenum(HyperionAcquisitionData));
HyperionSunElevation = double(HyperionMetaData.PRODUCT_PARAMETERS.SUN_ELEVATION);
HyperionSunZenith = 90 - HyperionSunElevation;
HyperionSunAzimuth =  double(HyperionMetaData.PRODUCT_PARAMETERS.SUN_AZIMUTH);
HyperionSunLookAngle = double( HyperionMetaData.PRODUCT_PARAMETERS.SENSOR_LOOK_ANGLE) ;
%scaling factors for VNIR and SWIR regions
ScalingFactorVNIR = 40;
ScalingFactorSWIR = 80;

%for i = 1 : size(ListOfImageHyperion,1) - 2
    
    
    
    for j= 8:57
        
        ImageInHyperion = double(imread(strcat(ImageLocationHyperion,'\',BaseName,'_','B',...
                                num2str(j,'%03d'),'_L1T.TIF')));

        %crop the ROI
        CroppedImageHyperion(:,:) = ImageInHyperion( UL_Column:LR_Column,UL_Row:LR_Row); 

        Temp = CroppedImageHyperion;
            
        %exclude the non image data
        NonZeroImageData = (Temp(Temp~=0)); 
            
        %calculate the mean of image data
        MeanNonZeroImageData = mean2(NonZeroImageData);
        StdNonZeroImageData = std2(NonZeroImageData);
            
        RadianceMeanImage(j) = (MeanNonZeroImageData/ScalingFactorVNIR);
        RadianceSdImage(j) = (StdNonZeroImageData/ScalingFactorVNIR); 
            
        %calculating reflectance of the image
        ReflectanceMeanImage(j) = ((MeanNonZeroImageData/ScalingFactorVNIR)*...
                                    pi*SunDistance(doy)^2)/(EsunChkkur(j)*cosd(HyperionSunZenith));
        ReflectanceSdImage(j) = ((StdNonZeroImageData/ScalingFactorVNIR)*...
                                    pi*SunDistance(doy)^2)/(EsunChkkur(j)*cosd(HyperionSunZenith));  
        
        %MeanROIHyperion = mean2(CroppedImageHyperion);

        %HyperionRadiance(k) = MeanROIHyperion/40;
        %Mean(i) = MeanROIHyperion;
        
    end
    
    for j= 77:224
        
        ImageInHyperion = double(imread(strcat(ImageLocationHyperion,'\',BaseName,'_','B',...
                                num2str(j,'%03d'),'_L1T.TIF')));

        %crop the ROI
        CroppedImageHyperion(:,:) = ImageInHyperion( UL_Column:LR_Column,UL_Row:LR_Row); 

        Temp = CroppedImageHyperion;
            
        %exclude the non image data
        NonZeroImageData = (Temp(Temp~=0)); 
            
        %calculate the mean of image data
        MeanNonZeroImageData = mean2(NonZeroImageData);
        StdNonZeroImageData = std2(NonZeroImageData);
            
        RadianceMeanImage(j) = (MeanNonZeroImageData/ScalingFactorVNIR);
        RadianceSdImage(j) = (StdNonZeroImageData/ScalingFactorVNIR); 
            
        %calculating reflectance of the image
        ReflectanceMeanImage(j) = ((MeanNonZeroImageData/ScalingFactorVNIR)*...
                                    pi*SunDistance(doy)^2)/(EsunChkkur(j)*cosd(HyperionSunZenith));
        ReflectanceSdImage(j) = ((StdNonZeroImageData/ScalingFactorVNIR)*...
                                    pi*SunDistance(doy)^2)/(EsunChkkur(j)*cosd(HyperionSunZenith));  
        
   end
    
   
%end

RadianceMeanImage(58:76) = [];
RadianceMeanImage(1:7) = [];
RadianceSdImage(58:76) = [];
RadianceSdImage(1:7) = [];
       
ReflectanceMeanImage(58:76) = [];
ReflectanceMeanImage(1:7) = [];
ReflectanceSdImage(58:76) = [];
ReflectanceSdImage(1:7) = [];
       
HyperionWavelength(225:end) = [];
HyperionWavelength(58:76) = [];
HyperionWavelength(1:7) = [];
       
figure('Color',[1 1 1])
plot(HyperionWavelength,ReflectanceMeanImage,'g','LineWidth',2);hold on
plot(HyperionWavelength,(ReflectanceMeanImage + ReflectanceSdImage),...
            'r','LineWidth',2);hold on
plot(HyperionWavelength,(ReflectanceMeanImage - ReflectanceSdImage),...
            'r','LineWidth',2);grid on
xlabel('Wavelength(\mum)','Fontsize',24,'FontName','Times New Roman');
ylabel('Reflectance','Fontsize',24,'FontName','Times New Roman');
title('Hyperion data over lake Tahoe','Fontsize',30,'FontName','Times New Roman');
legend('Mean of an Image','Mean + Sd','Mean - Sd')
 
%{
figure('Color',[1 1 1])
 plot(HyperionWavelength(8:55),Mean(8:55),'r');hold on
 plot(HyperionWavelength(77:end),Mean(77:end),'r');grid on
 xlabel('Wavelength(nm)','Fontsize',24,'FontName','Times New Roman');
 ylabel('Digital Number','Fontsize',24,'FontName','Times New Roman');
 title('Hyperion Data over lake Tahoe','Fontsize',30,'FontName','Times New Roman');
%}
                    
%load the RSR of Landsat8 and Sentinal2

load('L8_rsr.mat');
L8Coastal = L8_rsr{1};
L8Blue = L8_rsr{2};
L8Green = L8_rsr{3};
L8Red = L8_rsr{4};
L8NIR = L8_rsr{5};
L8SWIR1 = L8_rsr{6};
L8SWIR2 = L8_rsr{7};

load('S2A_rsr.mat')
S2ACoastal = S2A_rsr{1};
S2ABlue = S2A_rsr{2};
S2AGreen = S2A_rsr{3};
S2ARed = S2A_rsr{4};
S2ANIR = S2A_rsr{9};
S2ASWIR1 = S2A_rsr{12};
S2ASWIR2 = S2A_rsr{13};

%{
subplot(2,4,1)
figure('Color',[1 1 1])
plot(L8Coastal(:,1),L8Coastal(:,2),'r','LineStyle','-','LineWidth',2); hold on
plot(S2ACoastal(:,1),S2ACoastal(:,2),'b','LineStyle','-','LineWidth',2); grid on
xlabel('Wavelength(\mum)','Fontsize',10,'FontName','Times New Roman');
ylabel('Relative Spectral Response','Fontsize',10,'FontName','Times New Roman');
title('RSR of Coastal band of L8 and S2A','Fontsize',12,'FontName','Times New Roman');
legend('RSR of L8 Coastal','RSR of S2A Coastal')
ylim([0 1.3])
hold on

subplot(2,4,2)
%figure('Color',[1 1 1])
plot(L8Blue(:,1),L8Blue(:,2),'r','LineStyle','-','LineWidth',2); hold on
plot(S2ABlue(:,1),S2ABlue(:,2),'b','LineStyle','-','LineWidth',2); grid on
xlabel('Wavelength(\mum)','Fontsize',10,'FontName','Times New Roman');
ylabel('Relative Spectral Response','Fontsize',10,'FontName','Times New Roman');
title('RSR of Blue band of L8 and S2A','Fontsize',12,'FontName','Times New Roman');
legend('RSR of L8 Blue','RSR of S2A Blue')
ylim([0 1.3])

subplot(2,4,3)
%figure('Color',[1 1 1])
plot(L8Green(:,1),L8Green(:,2),'r','LineStyle','-','LineWidth',2); hold on
plot(S2AGreen(:,1),S2AGreen(:,2),'b','LineStyle','-','LineWidth',2); grid on
xlabel('Wavelength(\mum)','Fontsize',10,'FontName','Times New Roman');
ylabel('Relative Spectral Response','Fontsize',10,'FontName','Times New Roman');
title('RSR of Green band of L8 and S2A','Fontsize',12,'FontName','Times New Roman');
legend('RSR of L8 Green','RSR of S2A Green')
ylim([0 1.3])

subplot(2,4,4)
%figure('Color',[1 1 1])
plot(L8Red(:,1),L8Red(:,2),'r','LineStyle','-','LineWidth',2); hold on
plot(S2ARed(:,1),S2ARed(:,2),'b','LineStyle','-','LineWidth',2); grid on
xlabel('Wavelength(\mum)','Fontsize',10,'FontName','Times New Roman');
ylabel('Relative Spectral Response','Fontsize',10,'FontName','Times New Roman');
title('RSR of Red band of L8 and S2A','Fontsize',12,'FontName','Times New Roman');
legend('RSR of L8 Red','RSR of S2A Red')
ylim([0 1.3])

subplot(2,4,5)
%figure('Color',[1 1 1])
plot(L8NIR(:,1),L8NIR(:,2),'r','LineStyle','-','LineWidth',2); hold on
plot(S2ANIR(:,1),S2ANIR(:,2),'b','LineStyle','-','LineWidth',2); grid on
xlabel('Wavelength(\mum)','Fontsize',10,'FontName','Times New Roman');
ylabel('Relative Spectral Response','Fontsize',10,'FontName','Times New Roman');
title('RSR of NIR band of L8 and S2A','Fontsize',12,'FontName','Times New Roman');
legend('RSR of L8 NIR','RSR of S2A NIR')
ylim([0 1.3])

subplot(2,4,6)
%figure('Color',[1 1 1])
plot(L8SWIR1(:,1),L8SWIR1(:,2),'r','LineStyle','-','LineWidth',2); hold on
plot(S2ASWIR1(:,1),S2ASWIR1(:,2),'b','LineStyle','-','LineWidth',2); grid on
xlabel('Wavelength(\mum)','Fontsize',10,'FontName','Times New Roman');
ylabel('Relative Spectral Response','Fontsize',10,'FontName','Times New Roman');
title('RSR of SWIR1 band of L8 and S2A','Fontsize',12,'FontName','Times New Roman');
legend('RSR of L8 SWIR1','RSR of S2A SWIR1')
ylim([0 1.3])

subplot(2,4,7)
%figure('Color',[1 1 1])
plot(L8SWIR2(:,1),L8SWIR2(:,2),'r','LineStyle','-','LineWidth',2); hold on
plot(S2ASWIR2(:,1),S2ASWIR2(:,2),'b','LineStyle','-','LineWidth',2); grid on
xlabel('Wavelength(\mum)','Fontsize',10,'FontName','Times New Roman');
ylabel('Relative Spectral Response','Fontsize',10,'FontName','Times New Roman');
title('RSR of SWIR2 band of L8 and S2A','Fontsize',12,'FontName','Times New Roman');
legend('RSR of L8 SWIR2','RSR of S2A SWIR2')
ylim([0 1.3])
%}


[LabelL8,L8BandedValue] = bander(HyperionWavelength,ReflectanceMeanImage,24);
[LabelS2A,S2ABandedValue] = bander(HyperionWavelength,ReflectanceMeanImage,32);

%Only put VIS,NIR ans SWIR band
L8BandedValue(8:9) = [];

S2AIndex = [1 2 3 4 9 12 13];
TempS2A = S2ABandedValue
S2ABandedValue =  S2ABandedValue(S2AIndex);

figure('Color',[1 1 1])
plot(L8BandedValue,'Color',[1 0 0],'MarkerFaceColor',[1 0 0],...
         'Marker','hexagram','MarkerSize',16,'Linestyle','None'); hold on
plot(S2ABandedValue,'Color',[0 1 0],'MarkerFaceColor',[0 1 0],...
         'Marker','o','MarkerSize',16,'Linestyle','None'); grid on
%plot(L8BandedValue,'r*'); hold on
%plot(S2ABandedValue,'b*'); grid on
xlabel('Band','Fontsize',20,'FontName','Times New Roman');
ylabel('Reflectance','Fontsize',20,'FontName','Times New Roman');
title('Comparision of banded value of L8 and S2A','Fontsize',24,'FontName','Times New Roman');
legend('Banded value of Landsat8','Banded value of Sentinal2A')

%SBAFS2A2L8 = L8BandedValue./S2ABandedValue;
SBAFL82S2A = S2ABandedValue./L8BandedValue;

figure('Color',[1 1 1])
plot(SBAFL82S2A,'Color',[1 0 0],'MarkerFaceColor',[1 0 0],...
     'Marker','hexagram','MarkerSize',20,'Linestyle','None');  grid on
xlabel('Band','Fontsize',20,'FontName','Times New Roman');
ylabel('Spectral Band Adjustment Factor(SBAF)','Fontsize',20,'FontName','Times New Roman');
title('Spectral Band Adjustment Factor(SBAF) for Landsat8 to Sentinal2A','Fontsize',24,'FontName','Times New Roman');


L8SolarZenith = 90 - 24.95;
S2ASolarZenith = 63.5; 

%CorrectedTOAReflectanceSentinal2A = (TOAReflectanceSentinal.*SBAFS2A2L8)*...
%                                   (cosd(L8SolarZenith)/cosd(S2ASolarZenith))
                               
CorrectedTOAReflectanceSentinal2A = (TOAReflectanceL8.*SBAFL82S2A)%*...
                                   %(cosd(S2ASolarZenith)/cosd(L8SolarZenith));
figure('Color',[1 1 1])
%plot(TOAReflectanceSentinal,'r*'); hold on
%plot(CorrectedTOAReflectanceSentinal2A,'b*'); grid on
plot(TOAReflectanceSentinal,'Color',[1 0 0],'MarkerFaceColor',[1 0 0],...
         'Marker','hexagram','MarkerSize',16,'Linestyle','None'); hold on
plot(CorrectedTOAReflectanceSentinal2A,'Color',[0 1 0],'MarkerFaceColor',[0 1 0],...
         'Marker','o','MarkerSize',16,'Linestyle','None'); grid on
xlabel('Band','Fontsize',20,'FontName','Times New Roman');
ylabel('Reflectance','Fontsize',20,'FontName','Times New Roman');
title('Comparision between raw and corrected reflectance of lake Tahoe using Sentinal2A','Fontsize',24,'FontName','Times New Roman');
legend('Raw reflectance of lake Tahoe Sentinal2A','Corrected reflectance of lake Tahoe Sentinal2A')  


figure('Color',[1 1 1])
plot(TOAReflectanceL8,'Color',[1 0 0],'MarkerFaceColor',[1 0 0],...
         'Marker','hexagram','MarkerSize',16,'Linestyle','None'); hold on
plot(CorrectedTOAReflectanceSentinal2A,'Color',[0 1 0],'MarkerFaceColor',[0 1 0],...
         'Marker','o','MarkerSize',16,'Linestyle','None'); grid on
xlabel('Band','Fontsize',20,'FontName','Times New Roman');
ylabel('Reflectance','Fontsize',20,'FontName','Times New Roman');
title('Comparision between raw L8 data and corrected Sentinal2A data over lake Tahoe','Fontsize',24,'FontName','Times New Roman');
legend('Raw reflectance of lake Tahoe Landsat8','Corrected reflectance of lake Tahoe Sentinal2A')

save('CorrectedTOAReflectanceSentinal2A.mat','CorrectedTOAReflectanceSentinal2A');


%calculate the relative difference between raw and corrected TOA of
%Sentinal2A
RelativeDifferenceSentinal = (-(TOAReflectanceSentinal - CorrectedTOAReflectanceSentinal2A)...
                              ./TOAReflectanceSentinal)*100

figure('Color',[1 1 1])
plot(RelativeDifferenceSentinal,'Color',[1 0 0],'MarkerFaceColor',[1 0 0],...
     'Marker','hexagram','MarkerSize',20,'Linestyle','None');  grid on
xlabel('Band','Fontsize',20,'FontName','Times New Roman');
ylabel('RelativeDifference(%)','Fontsize',20,'FontName','Times New Roman');
title('Relative difference between raw and corrected TOA reflectance of Sentinal2A over Lake Tahoe','Fontsize',24,'FontName','Times New Roman');
