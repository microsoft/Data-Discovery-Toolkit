# End to end walkthrough of identifying biases in a labeled image dataset 
In this walkthrough we will extract captions from a set of labeled images and identify biases in the data. 

We will be using the [imSitu](http://imsitu.org/) dataset, that classifies images based on the situation depicted in them (cooking, arranging, constructing...) 

The walkthrough consists of three steps. In the first step, we will create a sample of the data. For simplicity, we will use two categories: cleaning and not cleaning. In the second step, we will use Synapse to run a notebook that will add captions to each image. Lastly, we will use the captions to detect biases in the data.

## Step 1: Data Sampling
Since the imSitu data is large (3.7G), we will take a sample of cooking and non-cooking images. All of the steps can be found in this [notebook](create_sample.ipynb). The output of this stage will be a sample of a little over 1K images stored in `./dataset/imSitu_samples`.
One the sample is created, you can move to the second step. 

## Step 2: Image Captioning

### Upload the data

Upload the sample data created in **Step 1** to your primary ADLS account linked to your Synapse instance

### Run the image captioning notebook in Synapse

1. Follow the steps in the in the [Image Captioning Setup](/environment_preparation/README.md#image-captioning-setup).
1. Open the [Image Captioning Notebook](/synapse/notebooks/image_captioning/standalone_image_captioning.ipynb) in Synapse
2. Make the following changes:
```python
# The blob account name = [accountname]
account_name = "[your account name]"
# The name of the primary ADLS share
file_system_name="[your file storage name]"
# The blob account key [iufquq34r423r2==] - used to generate a SAS key
account_key = "[your account key]"
# The directory folders where your files reside  
directory_name='imSitu_samples'
# The name of the output file
output_filename = 'imSitu_captioned.csv'
```
3. Run all the cells. Running the whole dataset (1,244 images) withe the Medium cluster would take about 40 minutes to complete. 

4. Open the [coalesce notebook](/synapse/notebooks/coalesce.ipynb) and update the input and output file names. the input path must match the output path of the [Image Captioning Notebook](/synapse/notebooks/image_captioning/standalone_image_captioning.ipynb). 
5. Run all the cells in the [coalesce notebook](/synapse/notebooks/coalesce.ipynb). When the notebook finished running, there will be a single csv file containing all the captions.
6. Download the coalesced file to a local folder 

## Step 3: Finding Biases in the dataset
Open the [imSitu notebook](./imSitu.ipynb), set `data_path` to point to the annotations csv file and run all the cells

