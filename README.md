# ufBGCtoolbox
ufBGCtoolbox: a tool for the mining of BGC domains and classes in metagenomic data. It consists of the following modules:
1. bgc_dom_annot: fast identification of BGC protein domains.  
2. bgc_dom_div: BGC domain-specific diversity analysis.  
3. bgc_model_class: BGC class relative count predictions.  

## Installation

ufBGCtoolbox consists of four dokcer images: 
1. epereira/ufBGCtolbox:bgc_dom_annot 
2. epereira/ufBGCtolbox:bgc_dom_div 
3. epereira/ufBGCtolbox:bgc_dom_merged_div 
4. epereira/ufBGCtolbox:bgc_class_models

Before running ufBGCtoolbox it is necessary to install [docker](https://www.docker.com/).

Then just clone the github repository:
```
git clone git@github.com:pereiramemo/ufBGCtoolbox.git
```

All four images are in [dockerhub](https://hub.docker.com/). These will be downloaded automatically the first time you run the scripts.

## Documentation

### 1. bgc_dom_annot
This first module runs uproc using a BGC domain profile database. It takes as an input metagenomic unassembled data and outputs an abundance BGC domain profile table.

See help
```
sudo ./run_bgc_dom_annot.bash . . --help
```

### 2. bgc_dom_div
bgc_dom_div has two different modes: sample and merge. The sample mode takes as an input metagenomic unassembled data and generates a targeted assembly of the domains. Subsequently, it clusters the assembled sequences and places these on pre-computed reference trees and computes the Shannon diversity index. The merge mode integrates the sample mode results and computes the diversity based on rarefied subsamples.

See help
```
sudo ./run_bgc_dom_div.bash sample . . . --help

```
See help
```
sudo ./run_bgc_dom_div.bash merge . . --help

```

### 3. bgc_class_models
This module is based on the [bgcpred](https://github.com/pereiramemo/bgcpred) R package, which includes a library of BGC class abundance models. Based on the domain profile generated by bgc_dom_annot, this module computes the BGC class abundance profile.

See help
```
sudo ./run_bgc_class_models.bash . . --help
```

### See the [wiki](https://github.com/pereiramemo/ufBGCtoolbox/wiki) for further documentation.

