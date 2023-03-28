# Clustering documents

This section deals with text documents which may be unstructured documents or structured forms. These documents may PDFs, Word documents, raw text or even scanned images of a form.

## Normalising the data

Before data can be clustered, it needs to be extracted to a common format. If the data is available in a variety of formats such as .doc, .pdf etc, the raw text will first need to be extracted.

[Apache Tika](https://tika.apache.org/) is an open source solution that can assist with this and it can be deployed in a number of ways, for example on Azure Synapse or as a containerised solution.

## Working with scanned images

If the documents are scanned images, typically in .jpg or .png format, they will first need to have an OCR solution run on them to extract the text. Refer to the [Knowledge Extraction Playbook](https://github.com/microsoft/knowledge-extraction-recipes-forms) for more information on working with forms and applying pre-processing techniques to scanned documents to get the best results from OCR.

## Selecting the type of feature extraction to apply

This Playbook currently implements 3 feature extractors for clustering the text documents:

1) [Term Frequency - Inverse Document Frequency (TF-IDF)](https://en.wikipedia.org/wiki/Tf%E2%80%93idf). This is a simple but effective approach, particularly at scale due to it being natively implemented within SparkML. It is also more language resilient.

1) [spaCy]((https://spacy.io/)) provides a range of optimised language models, from lightweight to quite large transformer models in a convenient and feature rich NLP library. This is a decent option for language that is not too domain specific. Fine tuning and multiple language options are available.

1) [HuggingFace transformer based language models](https://huggingface.co/) state of the art language models trained on large amounts of data. Multiple models for multiple languages are available for fine tuning. This is a good option to select if the language used is very domain specific and fine tuning needs to take place.