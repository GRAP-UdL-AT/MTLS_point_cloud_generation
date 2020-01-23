function track=track_formation_GPS_v21(folder,file_GPS,file_velodyne,versio,frame_min,frame_max,samp_GPS,filt_size,SmoothingParam,K,filt_size_z,SmoothingParam_z,K_z,factor_correct_temps)  
%Verció del dia 05/06/2018: En aquesta versió solament es tracten les
%dades del gps mentre s'escaneja amb el velodyne. Els angles de la
%trajectoria s'agafen amb el primer i últim punt de la trajectoria.
%Aquesta verció es valida per els nuvols processats amb el VeloView.3.5

%Lectura dades del TRACK original
data_original=dlmread([ folder '/' file_GPS]);
alldata=data_original(1:samp_GPS:end,:);


%%
%Calcul hora GPS en milisegons
hour=fix(alldata(:,1)/10000);
minute=fix((alldata(:,1)-hour*10000)/100);
second=alldata(:,1)-hour*10000-minute*100;
time_GPS(:,1)=(hour*3600+minute*60+second)*1000000;

%%
%Identificació inici Velodyne
data_velodyne=csvread([folder '/' file_velodyne sprintf('%04d',frame_min) ').csv'],1,0); %agafem les dades del frame_min
data_velodyne(:,11)=data_velodyne(:,11)+factor_correct_temps; % Per resoldre l'error. Per un arxiu normal s'ha de borrar. Modificació realitzada el dia 21/06/2019 amb l'ajuda del Jordi Gené.
inici_velodyne=0; %linea del track -1
    while time_GPS(inici_velodyne+1,1)<data_velodyne(1,11) %mentres (t_track < t_velodyne)
        inici_velodyne=inici_velodyne+1;
    end
clear data_velodyne

%Identificació final Velodyne
data_velodyne=csvread([folder '/' file_velodyne sprintf('%04d',frame_max) ').csv'],1,0); %agafem les dades del frame_max
data_velodyne(:,11)=data_velodyne(:,11)+factor_correct_temps; % Per resoldre l'error. Per un arxiu normal s'ha de borrar. Modificació realitzada el dia 21/06/2019 amb l'ajuda del Jordi Gené.
final_velodyne=inici_velodyne+1; %linea del track -1
    while time_GPS(final_velodyne,1)<data_velodyne(end,11) %mentres (t_track < t_velodyne)
        final_velodyne=final_velodyne+1;
    end    
clear data_velodyne    
    
data_treated_GPS=time_GPS(inici_velodyne-max([ceil(K/2),ceil(filt_size/2)]):final_velodyne+max([ceil(K/2),ceil(filt_size/2)]));
data=alldata(inici_velodyne-max([ceil(K/2),ceil(filt_size/2)]):final_velodyne+max([ceil(K/2),ceil(filt_size/2)]),:);
data_size=size(data,1);
%%
%Creació del filtre
filt(1:filt_size)=1/filt_size;
filt_z(1:filt_size_z)=1/filt_size_z;

%%
%filtratge corva GPS
GPS_x_filt=conv(data(:,3),filt,'same'); %Cordenadas X filtradas
GPS_y_filt=conv(data(:,4),filt,'same'); %Cordenadas Y filtradas
GPS_z_filt=conv(data(:,5),filt_z,'same'); %Cordenadas Z filtradas

%%
%Trajectoria GPS spline
if SmoothingParam~=1
    fx=fit(data(:,1),GPS_x_filt,'smoothingspline','SmoothingParam',SmoothingParam);
    data_treated_GPS(:,2)=feval(fx,data(:,1));
    fy=fit(data(:,1),GPS_y_filt,'smoothingspline','SmoothingParam',SmoothingParam);
    data_treated_GPS(:,3)=feval(fy,data(:,1));
    else 
        data_treated_GPS(:,2)=GPS_x_filt;
        data_treated_GPS(:,3)=GPS_y_filt;
end

if SmoothingParam_z~=1
    fz=fit(data(:,1),GPS_z_filt,'smoothingspline','SmoothingParam',SmoothingParam_z);
    data_treated_GPS(:,4)=feval(fz,data(:,1));
    else 
        data_treated_GPS(:,4)=GPS_z_filt;
end

%Representació corva GPS (Si no es una trajectoria recta, aquesta verció no
%es valida!!!)
h1=figure;
plot(data(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),3),data(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),4),'.')
hold on
plot(data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),2),data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),3))
h2=figure;
plot(data(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),5))
hold on
plot(data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),4))
saveas (h1,[ folder '/' file_GPS(1:(end-4)) '_trayectoriaXY_' versio ]);   
saveas (h2,[ folder '/' file_GPS(1:(end-4)) '_trayectoriaZ_' versio ]);    

%%
%Calculs angles matriu de rotació

% for i=floor(max(K,K_z)/2)+1:(data_size-2-floor(max(K,K_z)/2))
%     data_treated_GPS(i,5)=data_treated_GPS(i+floor(K/2),2)-data_treated_GPS(i-floor(K/2),2); %calcul de a=(X_filt1-X_filt0)
%     data_treated_GPS(i,6)=data_treated_GPS(i+floor(K/2),3)-data_treated_GPS(i-floor(K/2),3); %calcul de b=(Y_filt1-Y_filt0)
%     data_treated_GPS(i,7)=data_treated_GPS(i+floor(K_z/2),4)-data_treated_GPS(i-floor(K_z/2),4); %calcul de c=(Z_filt1-Z_filt0)
%     data_treated_GPS(i,8)=sqrt(data_treated_GPS(i,5)^2+data_treated_GPS(i,6)^2); %calcul de d=sqrt(a^2+b^2)
%     
%     
%     if (data_treated_GPS(i,6)==0 && data_treated_GPS(i,5)>0)
%         data_treated_GPS(i,9)=90; %valor de \theta si b=0 i a>0
%     else if (data_treated_GPS(i,6)==0 && data_treated_GPS(i,5)<0)
%             data_treated_GPS(i,9)=270; %valor de \theta si b=0 i a<0
%         else if data_treated_GPS(i,6)>0
%                 data_treated_GPS(i,9)=180-atand(data_treated_GPS(i,5)/data_treated_GPS(i,6)); %valor de \theta si b>0
%             else
%                     data_treated_GPS(i,9)=atand(-data_treated_GPS(i,5)/data_treated_GPS(i,6));  %valor de \theta si b<0
%             end
%         end
%     end
%     
%     if data_treated_GPS(i,7)==0
%         data_treated_GPS(i,10)=90; %valor de \phi si c=0
%     else if data_treated_GPS(i,7)>0
%             data_treated_GPS(i,10)=atand(data_treated_GPS(i,8)/data_treated_GPS(i,7)); %valor de \phi si c>0
%         else 
%             data_treated_GPS(i,10)=180+atand(data_treated_GPS(i,8)/data_treated_GPS(i,7)); %valor de \phi si c<0
%         end
%     end
%      
% end

% data_treated_GPS(:,9)=mean(data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),9));
% data_treated_GPS(:,10)=mean(data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),10));


    a=data_treated_GPS((end-max([ceil(K/2),ceil(filt_size/2)])),2)-data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]),2); %calcul de a=(X_filt1-X_filt0)    
    b=data_treated_GPS((end-max([ceil(K/2),ceil(filt_size/2)])),3)-data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]),3);
    c=data_treated_GPS((end-max([ceil(K/2),ceil(filt_size/2)])),4)-data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]),4);
    d=sqrt(a^2+b^2); %calcul de d=sqrt(a^2+b^2)
    
    
       if (b==0 && a>0)
        data_treated_GPS(:,9)=90; %valor de \theta si b=0 i a>0
    else if (b==0 && a<0)
            data_treated_GPS(:,9)=270; %valor de \theta si b=0 i a<0
        else if b>0
                data_treated_GPS(:,9)=180-atand(a/b); %valor de \theta si b>0
            else
                    data_treated_GPS(:,9)=atand(-a/b);  %valor de \theta si b<0
            end
        end
    end
    
    if c==0
        data_treated_GPS(:,10)=90; %valor de \phi si c=0
    else if c>0
            data_treated_GPS(:,10)=atand(d/c); %valor de \phi si c>0
        else 
            data_treated_GPS(:,10)=180+atand(d/c); %valor de \phi si c<0
        end
    end 



 data_treated_GPS(data_size,5:10)=data_treated_GPS(data_size-1,5:10);
 data_treated_GPS(:,11:13)=data(:,3:5); %També guardem els valors XYZ originals
 %%
 %enviament de dades (Solament s'envia Hora GPS i Trajectoria filtrada)
 track=data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),[1,2,3,4,9,10,11,12,13]);

%%
% %Creació arxiu .txt on es guardaran valors del GPS tractats
fileID=fopen([ folder '/' file_GPS(1:end-4) '_tractat_' versio '.txt'],'w');
fprintf(fileID,'%11s\t%11s\t%11s\t%8s\t%8s\t%8s\t%11s\t%11s\t%11s\r\n', 'Hora GPS','Xgps_filtrat','Ygps_filtrat','Zgps_filtrat','\theta','\phi','Xgps_original','Ygps_original','Zgps_original');
fprintf(fileID,'%.0f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\r\n',data_treated_GPS(max([ceil(K/2),ceil(filt_size/2)]):(end-max([ceil(K/2),ceil(filt_size/2)])),[1,2,3,4,9,10,11,12,13])');
end


