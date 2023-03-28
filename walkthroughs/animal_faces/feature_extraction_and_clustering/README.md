# End to end walkthrough of feature extraction and clustering - animal faces

In this walkthrough we will cover each step in the process to extract features from a set of images, perform inference, and cluster the extracted features and present the final result in a [PowerBI](https://powerbi.microsoft.com/en-us/) dashboard.

For this walkthrough we will be using a sample from the [Kaggle Animal Faces dataset](https://www.kaggle.com/datasets/andrewmvd/animal-faces) which can be found [here](/data/images/animal_faces/walkthrough/).

## Upload your data

Upload the [data](/data/images/animal_faces/walkthrough/) to your primary ADLS account linked to your Synapse instance, see below:

<img src="../../../images/animal_faces.png" alt="animal faces data structure in synapse" width="250"/>

## Run the image clustering notebook in Synapse

### On setting the number of clusters

We have set the number of clusters here to be 3, for this dataset we know there are 3 classes. However, for an unknown data set we can try to infer the number of clusters by using techniques such as the [Silhouette Method](https://en.wikipedia.org/wiki/Silhouette_(clustering)) or the [Elbow method](https://en.wikipedia.org/wiki/Elbow_method_(clustering)), or alternatively run the clustering with a few different values to find the best fit. Typically, if cluster 0 contains too many and diverse files, the number of clusters selected is too low.

This process should run for around 2-3 minutes on the smallest cluster and node size, see below:

<img src="../../../images/text_clustering_complete.png" alt="animal faces output files per partition" width="450"/>

Open the [Image Clustering Notebook](/synapse/notebooks/image_clustering/standalone_image_clustering.ipynb) in your Synapse instance, populate the parameters cell with the appropriate values:

```python

# The input directory where the images reside, can be nested
input_directory = 'abfss://share@[accountname].dfs.core.windows.net/animal_faces/walkthrough/'
# The number of clusters - this can be automated or start with a guesstimate
number_of_clusters = 3
# The output directory where the output file will be written to
output_directory = 'abfss://share@[accountname].dfs.core.windows.net/animal_faces/output/'
# The name of the output file
output_filename = 'animal_faces_clustered_walkthrough.csv'

# The blob account url - https://[accountname].blob.core.windows.net
account_url = "https://[accountname].blob.core.windows.net"
# The blob account name = [accountname]
account_name = ''
# The blob account key [iufquq34r423r2==] - used to generate a SAS key
account_key = ''

# The name of the primary ADLS share
file_system_name="share"
# The directory folders where your files reside  
directory_name='animal_faces/walkthrough'  # bbc/videos/

# If this is set to True then the Coalesce notebook will need to be run to merge the partition files into a single file
LOW_MEMORY_MODE = True
```

Run all the cells.

With the smallest cluster size in Synapse, namely size small and with 3 nodes, this should take around 2-3 minutes to complete, see below:

<img src="../../../images/clustering_complete.png" alt="animal faces data structure in synapse" width="450"/>

We have now generated the clusters for our images and written the output. However if you navigate to this output you will see that it is actually a folder. See below:

<img src="../../../images/animal_face_clustering_output.png" alt="animal faces data output in synapse" width="250"/>

As we ran this process in `LOW_MEMORY_MODE`, we wrote an output file per Synapse Spark partition. Inspecting the contents of the folder should yield a file per partition. See below:

<img src="../../../images/animal_face_clustering_file_per_partition.png" alt="animal faces output files per partition" width="250"/>

We now need to rewrite these files into a single file, and in a new Synapse session to avoid running out of memory on the driver node.

## Run the coalesce notebook for the image captioning output

We will now run the [coalesce notebook](/synapse/notebooks/coalesce.ipynb) which write all partition files to a single file that we can work with.

Populate the parameters cell with the appropriate values:

```python
# The input file directory and file name 
input_filename = "abfss://share@datadiscoverypipeline.dfs.core.windows.net/animal_faces/output/animal_faces_clustered_walkthrough.csv"
# The output file directory and file
output_filename = "abfss://share@datadiscoverypipeline.dfs.core.windows.net/animal_faces/output/animal_faces_clustered_single_walkthrough.csv"
```

We now have a single file that contains our image labels and coordinates and should look like the image below:

<img src="../../../images/clustering_dataframe_display.png" alt="animal faces output files per partition" width="650"/>

## Run the coalesce notebook for the text clustering output

We will now need to run the [coalesce notebook](/synapse/notebooks/coalesce.ipynb) again which write all partition files to a single file that we can work with.

## Optional: Check the generated blob SAS keys and paths

The blob paths do not generate correctly when we work with a nested directory structure where the images are class specific folders. We would like to be able to dislay the images correctly when we display the cluster results within PowerBI.

Open the [Fix SAS Keys and paths notebook](../../../jupyter/fix_sas_keys_and_paths.ipynb) and populate the values in the parameters cell with the appropriate values:

```python
# The path and file name to your input file to be corrected
INPUT_FILE = "/Users/shanepeckham/Downloads/animal_faces_captioned_single_clustered_single_walkthrough.csv"
# The path and file name to write the corrected file to
OUTPUT_FILE = "/Users/shanepeckham/Downloads/animal_faces_captioned_single_clustered_single_walkthrough.csv"

# Value in days that we want the SAS key to be valid for
SAS_VALIDITY = 100

# Your ADLS account name
account_name = ''
# Your ADLS account key
account_key = ''

# The name of your primary ADLS share folder
file_system_name="share"
# The directory path - no trailing /
directory_name='animal_faces/walkthrough'

# The full storage path
storage_path = "https://[accountname].blob.core.windows.net/share/"
```

Run all the cells and follow the instructions in the notebook.

We now have a file with clustered images and blob paths that we can import into PowerBI!

## Create a PowerBI report

[See how to create a simple but powerful interactive report](../../powerBI/README.md#creating-an-interactive-image-clustered-dashboard)