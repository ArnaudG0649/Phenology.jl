```@meta
CurrentModule = Phenology
```

## Temperatures data compatibility

As you can see in [Phenological models for each species](@ref), each function that predicts phenological dates from temperatures have methods which take in arguments data temperatures either as vector (for exemple `TG_vec`), dataframe or .txt file. In this page we will explain which temperatures data file this package can handle and how the data is extracted to be used.

Below we present the two types of file in format .txt tolerated by this package : 

- Recorded temperatures data file from the [European Climate Assessment and Dataset (abbreviated ECA&D)](https://www.ecad.eu/dailydata/predefinedseries.php). The name of the file has to start with "TN", "TG" or "TX" to not be miskaten with the second type of file : 

- Climate projections collected on the portal [DRIAS *Les futurs du climat*](https://www.drias-climat.fr/).

Some data file exemples are available in the `station` folder on the github repository of the package. 
This package has functions which can read and clean the data temperatures and their dates and return them in a dataframe object :

```@docs
Phenology.extract_series
Phenology.truncate_MV
```

Some functions (like [`Phenology.Apple_Phenology_Pred`](@ref)) can take as arguments directly the name of the file to return phenology predictions by calling a method which itself calls `extract_series`. They can also take dataframes which have a `DATE` and `TN`, `TG` or `TX` columns.
Because some phenological models need daily temperatures of multiple type, if they are extracted from different files with different timelines, we need to truncate this data to have a common timeline. This is the role of `Common_indexes` : 

```@docs
Phenology.Common_indexes
```

