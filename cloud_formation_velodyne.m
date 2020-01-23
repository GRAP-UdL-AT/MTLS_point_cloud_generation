%Point cloud generation from GPS and Velodyne data
%Date: 21/01/2020: En aquesta versió solament es tracten les
%dades del gps mentre s'escaneja amb el velodyne. També es concidera que 
%els punts d'un frame s'adquireixen en pos_per_frame instants diferents(mateixes
%coordenades del GPS). Els angles de la
%trajectoria s'agafen amb el primer i últim punt de la trajectoria.
%This version is valid for data acquired with VeloView.3.5
%No agafa els punts més allunyats de 4 metres

close all
clear, clc

%Per calcular el nuvol de punts, s'ha d'afegir una linea a l'excel
folder_sup=['E:\Detecció Fruits 2017\velodyne_vent\code_generacio_nuvols\test_data']; %folder where file "dades_preparation_cloud_formation_velodyne.xlsx" is placed
[data,text,alldata]=xlsread([ folder_sup '/dades_preparation_cloud_formation_velodyne.xlsx']); %Lectura arxiu excel.
beams_split=0; % 1: Si es vol separar feixos laser , 0: si no es vol separar feixos.
subsampling=0; % 1: Se es vol fer un arxiu amb subsampling, 0: si no es vol fer subsampling
dist_min=-4; % distancia mínima mesurada. Si es un número positiu solament s'escaneja el costat esquerra.
dist_max=4; % distancia màxima mesurada. Si es un número negatiu solament s'escaneja el costat dret
pos_per_frame=8; %numero de posicions GPS que s'agafen per frame
scrip_version='v27';
pixel_dim=0.004;
%factor_correct_temps=28790668987;


%%
for num=1:1 %indicar el num de files de l'arxiu "dades_cloud_formation_velodyne.xlsx" que es vol calcular
factor_correct_temps=data(num,18);
%%
tic;
disp('inici processat')
folder=char(strcat(folder_sup,alldata(num+1,2)));
file_GPS=char(alldata(num+1,3));
file_velodyne=char(alldata(num+1,4));
versio=num2str(data(num,1));

ofset_lidar(1)=data(num,5); %Distancia X entre Antena GPS i LIDAR Mirar als apunts per saber el criteri de positiu-negatiu
ofset_lidar(2)=data(num,6); %Distancia Y entre Antena GPS i LIDAR Mirar als apunts per saber el criteri de positiu-negatiu
ofset_lidar(3)=data(num,7); %Distancia Z entre Antena GPS i LIDAR Mirar als apunts per saber el criteri de positiu-negatiu
frame_min=data(num,8);
frame_max=data(num,9);

samp_GPS=data(num,10); %intervalo mostreo GPS
samp_lidar=data(num,11); %intervalo mostreo frames
filt_size=data(num,12); %Dimensió del filtre (número de valors dels quals fa la mitjana)
K=data(num,13);   %Valors extrems dels quals es calcula l'angle.Entre X0 i X1 hi ha K valors.
SmoothingParam=data(num,14); %Valor d'alleugerament corva spline
filt_size_z=data(num,15); %Dimensió del filtre de l'eix Z (número de valors dels quals fa la mitjana)
K_z=data(num,16);    %Valors extrems dels quals es calcula l'angle.Entre Z0 i Z1 hi ha K valors. (Eix Z)
SmoothingParam_z=data(num,17); %Valor d'alleugerament corva spline (eix Z)


%%
%Filtratge dades GPS i calcul paràmetres matriu de rotació
disp('inici track')
time=toc;
track=track_formation_GPS(folder,file_GPS,file_velodyne,versio,frame_min,frame_max,samp_GPS,filt_size,SmoothingParam,K,filt_size_z,SmoothingParam_z,K_z,factor_correct_temps); %Es crida la funció track_formation_GPS (Programa escrit apart)
disp(strcat('final track ',num2str(toc-time),' s'));


%%
%Canvi de coordenades mitjançant la matriu de tranlació i rotació


k=1; %linea del track    
err_frame=[];
for i=frame_min+1:samp_lidar:frame_max+1 %bucle per cada frame
    disp(strcat('inici frame ',num2str(i)));
    time=toc;
    
    %agafem les dades de un frame:
    data_velodyne_all=csvread([folder '/' file_velodyne sprintf('%04d',i-1) ').csv'],1,0); %agafem les dades de un frame
    trees_Idx=(~(data_velodyne_all(:,1)<data(num,19) & ...
                 data_velodyne_all(:,1)>data(num,20) & ...
                 data_velodyne_all(:,2)<data(num,21) & ...
                 data_velodyne_all(:,3)<data(num,23) & ...
                 data_velodyne_all(:,3)>data(num,24)) & ...
                 (dist_min<data_velodyne_all(:,1)&data_velodyne_all(:,1)<dist_max) & ...
                 data_velodyne_all(:,2)>data(num,25));
    %data_velodyne_dist=data_velodyne_all((dist_min<data_velodyne_all(:,1)&data_velodyne_all(:,1)<dist_max),:);
    data_velodyne_dist=data_velodyne_all(trees_Idx,:);
%     pc=pointCloud(data_velodyne_dist(:,1:3));
%     pcshow(pc)
    dataSize=size(data_velodyne_dist,1);
    if size(data_velodyne_dist,1)>pos_per_frame
        for j=1:pos_per_frame
        initialPoint=floor((dataSize-(pos_per_frame+1-j)*dataSize/pos_per_frame+1));
        finalPoint=floor(initialPoint+dataSize/pos_per_frame)-1;
        data_velodyne=data_velodyne_dist(initialPoint:finalPoint,:);
        data_treated_frame=zeros(size(data_velodyne,1),5);
        %calcul coodenada final per cada frame
            if (data_velodyne(ceil(size(data_velodyne,1)/2),11)+factor_correct_temps)>track(end,1)
                err_frame=[err_frame;i-1];
            else
                while track(k,1)<(data_velodyne(ceil(size(data_velodyne,1)/2),11)+factor_correct_temps) %mentres (t_track < t_velodyne)
                        k=k+1;
                end
            end

            T(1,1)=cosd(track(k-1,5));
            T(1,2)=-sind(track(k-1,5))*cosd(track(k-1,6));
            T(1,3)=sind(track(k-1,5))*sind(track(k-1,6));
            T(2,1)=sind(track(k-1,5));
            T(2,2)=cosd(track(k-1,5))*cosd(track(k-1,6));
            T(2,3)=-cosd(track(k-1,5))*sind(track(k-1,6));
            T(3,1)=0;
            T(3,2)=sind(track(k-1,6));
            T(3,3)=cosd(track(k-1,6));
            %Translació
            T(1,4)=interp1([track(k-1:k,1)],[track(k-1:k,2)],(data_velodyne(ceil(size(data_velodyne,1)/2),11)+factor_correct_temps)); %Interpolacion X
            T(2,4)=interp1([track(k-1:k,1)],[track(k-1:k,3)],(data_velodyne(ceil(size(data_velodyne,1)/2),11)+factor_correct_temps)); %Interpolacion Y
            T(3,4)=interp1([track(k-1:k,1)],[track(k-1:k,4)],(data_velodyne(ceil(size(data_velodyne,1)/2),11)+factor_correct_temps)); %Interpolacion Z
            T(4,1:4)=[0 0 0 1];

            %Calcul X Y Z respecte el mon
            data_treated_frame(:,1:3)=[T(1:3,:)*[data_velodyne(:,1)-ofset_lidar(1), data_velodyne(:,2)-ofset_lidar(2),data_velodyne(:,3)-ofset_lidar(3),ones(size(data_velodyne,1),1)]']';
            data_treated_frame(:,4:5)=data_velodyne(:,7:8);
            data_treated_frame(:,6)=i-1;   % Afegim el número d'Scan a la matriu
            data_treated_frame(:,7)=atan2(data_velodyne(:,4),data_velodyne(:,5));   % Aquí hi calcularem l'angle. NOTA: és important el punt després del primer terme de la divisió.
            data_treated_frame(:,8)=data_velodyne(:,2)-data(num,25);
            
            %Guardem dades frame
            fileID=fopen([ folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '.txt'],'a+');
        %     if i==frame_min+1
        %     fprintf(fileID,'%6s\t%11s\t%11s\t%0s\t%0s\r\n', 'X','Y','Z','Intensity','laser_ID');
        %     end
            fprintf(fileID,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\t%.0f\t%.3f\t%.3f\r\n',data_treated_frame');
            clear data_treated_frame data_velodyne
            fclose('all');
        end
    end
    
    
end
  disp(strcat('final processat en ',num2str(toc),'s'));
  %disp(strcat('Frames amb time error: ',strjoin(arrayfun(@(x) num2str(x),err_frame,'UniformOutput',false),',')))
  disp(['Frames amb time error: [' num2str(err_frame(:).') ']']) ;  % Nova línia de codi per substituïr l'anterior, segons Jordi Gené.

%% Separació feixos
 if beams_split
          
        %Obrim el núvol 3D
        data_nuvol=dlmread([ folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '.txt']); %agafem un nuvol 3D del velodyne

        fileID0=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_0.txt'],'a+');
        fileID1=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_1.txt'],'a+');
        fileID2=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_2.txt'],'a+');
        fileID3=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_3.txt'],'a+');        
        fileID4=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_4.txt'],'a+');        
        fileID5=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_5.txt'],'a+');        
        fileID6=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_6.txt'],'a+');       
        fileID7=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_7.txt'],'a+');        
        fileID8=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_8.txt'],'a+');        
        fileID9=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_9.txt'],'a+');        
        fileID10=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_10.txt'],'a+');        
        fileID11=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_11.txt'],'a+');        
        fileID12=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_12.txt'],'a+');        
        fileID13=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_13.txt'],'a+');        
        fileID14=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_14.txt'],'a+');        
        fileID15=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_15.txt'],'a+');        
        
        for j=1:size(data_nuvol,1)
            if data_nuvol(j,5)==0
                fprintf(fileID0,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');
            elseif  data_nuvol(j,5)==1    
                fprintf(fileID1,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');
            elseif  data_nuvol(j,5)==2        
                fprintf(fileID2,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');
            elseif  data_nuvol(j,5)==3
                fprintf(fileID3,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');
            elseif  data_nuvol(j,5)==4
                fprintf(fileID4,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');
            elseif  data_nuvol(j,5)==5
                fprintf(fileID5,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');
            elseif  data_nuvol(j,5)==6
                fprintf(fileID6,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');
            elseif  data_nuvol(j,5)==7
                fprintf(fileID7,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');    
            elseif  data_nuvol(j,5)==8
                fprintf(fileID8,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');    
            elseif  data_nuvol(j,5)==9
                fprintf(fileID9,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');    
            elseif  data_nuvol(j,5)==10
                fprintf(fileID10,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');  
            elseif  data_nuvol(j,5)==11
                fprintf(fileID11,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');    
            elseif  data_nuvol(j,5)==12
                fprintf(fileID12,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');    
            elseif  data_nuvol(j,5)==13
                fprintf(fileID13,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');    
            elseif  data_nuvol(j,5)==14
                fprintf(fileID14,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');    
            elseif  data_nuvol(j,5)==15
                fprintf(fileID15,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol(j,:)');    
            end
       end
        fclose('all'); 
        clear data_nuvol;

 end
 
  %% Subsampling
  if subsampling
      for beam=0:15
       %Obrim el núvol 3D
            data_nuvol_beam=dlmread([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_' num2str(beam) '.txt']); %agafem un nuvol 3D del velodyne
            data_nuvol_beam(:,1:3)=round((data_nuvol_beam(:,1:3))/pixel_dim)*pixel_dim;
            [G, D1, D2, D3] = findgroups(data_nuvol_beam(:,1), data_nuvol_beam(:,2),data_nuvol_beam(:,3));
            M1 = splitapply(@mean, data_nuvol_beam(:, 4), G);
            M2 = splitapply(@mean, data_nuvol_beam(:, 5), G);
            data_nuvol_beam_gruped=[D1,D2,D3,M1,M2];
            nuvol_3D=zeros(1,size(data_nuvol_beam,2));

            fileID=fopen([folder '/' file_velodyne(1:end-8) '_POINT_CLOUD_' scrip_version '_' versio '-beam_' num2str(beam) '_subsamp.txt'],'a+');
            fprintf(fileID,'%.4f\t%.4f\t%.4f\t%.0f\t%.0f\r\n',data_nuvol_beam_gruped');
            fclose('all');

      end
  end
  
end
  

 







