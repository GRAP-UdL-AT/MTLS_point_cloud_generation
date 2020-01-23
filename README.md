# Matlab implementation to generate 3D point clouds from data acquired with VLP-16 and GNSS GPS1200+

## Introduction
This project is a Matlab implementation to generate 3D point clouds from data acquired with a mobile terrestrial laser scanner (MTLS) comprised of a LiDAR sensor Velodyne VLP-16 (Velodyne LIDAR Inc., San Jose, CA, USA) and a GNSS position sensor GPS1200+ (Leica Geosystems AG, Heerbrugg, Swizeland). 

This implementation was used to generate the point clouds provided in LFuji-air dataset, which contains 3D LiDAR data of 11Fuji apple trees with the corresponding fruit position annotations. Find more information in:

* [LFuji-air dataset: annotated 3D LiDAR point clouds of Fuji apple trees for fruit detection scanned under different forced air flow conditions.](http://www.grap.udl.cat/en/publications/index.html). (submitted, not publicly available yet).



## Preparation 


First of all, clone the code
```
git clone https://github.com/GRAP-UdL-AT/MTLS_point_cloud_generation
```

Place  *.PCAP* files in the data folder */MTLS_point_cloud_generation/test_data*. Then convert _.PCAP_ files to _.CSV_ by using [Veloview software v3.5.0](https://velodynelidar.com/downloads/). This conversion generates a _.ZIP_ file, which should be unziped inside */MTLS_point_cloud_generation/test_data/velodyne_data*. 

### Prerequisites

* Matlab 2019b (we have not tested it in other matlab versions)
* Veloview 3.5.0

### Point cloud generation

Open the file ***/MTLS_point_cloud_generation/test_data/_dades_preparation_cloud_formation_velodyne.xlsx*** and set the folder and files names to be processed. Additionally, you can configure some parameters. This parameters depends on the experimental set-up and the scanning conditions, such as the offsets between LiDAR and GNSS sensors. 

Open matlab file :***/MTLS_point_cloud_generation/cloud_formation_velodyne.m*** and set the following parameter:
```
folder_sup = $”data_directory”$;    %folder where file "dades_preparation_cloud_formation_velodyne.xlsx" is placed
```
example:
```
folder_sup=['E:\Detecció Fruits 2017\velodyne_vent\code_generacio_nuvols\test_data']; 
```

Execute the file ***/MTLS_point_cloud_generation/cloud_formation_velodyne.m***.

## Authorship

This project is contributed by [GRAP-UdL-AT](http://www.grap.udl.cat/en/index.html).

Please contact authors to report bugs @ j.gene@eagrof.udl.cat


## Citation

If you find this implementation or the analysis conducted in our report helpful, please consider citing:

    @article{gene2019fruit,
	title={LFuji-air dataset: annotated 3D LiDAR point clouds of Fuji apple trees for fruit detection scanned under different forced air flow conditions.},
	author={Gen{\'e}-Mola, Jordi and Gregorio, Eduard and Cheein, Fernando Auat and Guevara, Javier and Llorens, Jordi and Sanz-Cortiella, Ricardo and Escol{\`a}, Alexandre and Rosell-Polo, Joan R},
	journal={Submitted},
    }

    @article{gene2019fruit,
	title={Fruit detection in an apple orchard using a mobile terrestrial laser scanner},
	author={Gen{\'e}-Mola, Jordi and Gregorio, Eduard and Guevara, Javier and Auat, Fernando and Sanz-Cortiella, Ricardo and Escol{\`a}, Alexandre and Llorens, Jordi and Morros, Josep-Ramon and Ruiz-Hidalgo, Javier and Vilaplana, Ver{\'o}nica and others},
	journal={Biosystems engineering},
	volume={187},
	pages={171--184},
	year={2019},
	publisher={Elsevier}
    }

    @article{gene2020fruit,
	title={Fruit detection, yield prediction and canopy geometric characterization using LiDAR with forced air flow},
	author={Gen{\'e}-Mola, Jordi and Gregorio, Eduard and Cheein, Fernando Auat and Guevara, Javier and Llorens, Jordi and Sanz-Cortiella, Ricardo and Escol{\`a}, Alexandre and Rosell-Polo, Joan R},
	journal={Computers and Electronics in Agriculture},
	volume={168},
	pages={105121},
	year={2020},
	publisher={Elsevier}
    }

