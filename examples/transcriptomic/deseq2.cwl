cwlVersion: v1.2
class: CommandLineTool
label: DESeq2 example
doc: |-
  This tool demonstrates how to perform a differential-expression analysis using the Bioconductor DESeq2 package. We use a container image that provides core Bioconductor components (release version 3.10) and use R code to install the DESeq2 packages as well as two helper packages.
requirements:
  ShellCommandRequirement: {}
  DockerRequirement:
    dockerImageId: deseq2
    dockerFile: |-
      FROM bioconductor/bioconductor_docker:RELEASE_3_11
      RUN R -e 'BiocManager::install(c("DESeq2"))'
      RUN R -e "install.packages(c('dplyr', 'readr'), repos='https://cloud.r-project.org')"
  NetworkAccess:
    class: NetworkAccess
    networkAccess: true
  InitialWorkDirRequirement:
    listing:
    - entryname: run_deseq2_analysis.R
      entry: |-
        library(dplyr)
        library(readr)
        library(DESeq2)
        
        read_counts_url = commandArgs()[8]
        phenotypes_url = commandArgs()[9]
        design_formula = commandArgs()[10]
        out_file_name = commandArgs()[11]
        
        # Read the data
        count_data = read_tsv(read_counts_url)
        phenotypes_data = read_tsv(phenotypes_url)
        
        # The readr package doesn't allow row names, so we pull those from the first column.
        # The readr package assigns a column name of X1 when the first column name is missing.
        count_row_names = pull(count_data, X1)
        count_data = select(count_data, -X1)
        count_data = as.matrix(count_data)
        rownames(count_data) = count_row_names
        
        phenotypes_row_names = pull(phenotypes_data, X1)
        phenotypes_data = select(phenotypes_data, -X1)
        phenotypes_data = as.data.frame(phenotypes_data)
        rownames(phenotypes_data) = phenotypes_row_names
        
        # These are the analysis steps.
        dds <- DESeqDataSetFromMatrix(countData = count_data,
                              colData = phenotypes_data,
                              design = as.formula(design_formula))
        dds <- DESeq(dds)
        res <- results(dds)
        
        # Now save the results, sorted by adjusted P-value.
        write.table(res[order(res$padj),], out_file_name, sep="\t", row.names=TRUE, col.names=NA, quote=FALSE)
inputs:
  read_counts_url:
    type: string
    doc: |-
      The URL of a tab-separated-value file containing RNA-Sequencing read counts (unnormalized). Rows should represent genes. Columns should represent biological samples. The header line should contain sample identifiers. The first column should contain gene identifiers.
  phenotypes_url:
    type: string
    doc: |-
      The URL of a tab-separated-value file containing metadata about the biological samples. Rows should represent biological samples. Columns should represent metadata variables (e.g., experimental group). The header line should contain column names. The first column should contain sample identifiers.
  design_formula:
    type: string
    doc: |-
      A formula that expresses how the counts for each gene might depend on one or more metadata variables. More details about this formula can be found at https://bioconductor.org/packages/release/bioc/manuals/DESeq2/man/DESeq2.pdf.
  output_file:
    type: string
    doc: |-
      Name of the output file that will be created. This will be a tab-separated file with differential-expression statistics.
      #Output_File=edam:format_3751
arguments:
  - shellQuote: false
    valueFrom: |-
      Rscript run_deseq2_analysis.R "$(inputs.read_counts_url)" "$(inputs.phenotypes_url)" "$(inputs.design_formula)" "$(inputs.output_file)"
outputs:
  output_file:
    type: File
    outputBinding:
      glob: "$(inputs.output_file)"
    doc: |-
      Output file matching the name specified in the "output_file" input.
    format: edam:format_3751
  standard_output:
    type: stdout
    format: edam:format_1964
  standard_error:
    type: stderr
    format: edam:format_1964
stdout: deseq2_output.txt
stderr: deseq2_error.txt
 
s:author:
  - class: s:Person
    s:name: Stephen Piccolo
    s:identifier: https://orcid.org/0000-0003-2001-5640
 
s:dateCreated: "2020-07-13"
s:license: https://spdx.org/licenses/Apache-2.0
 
$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
$schemas:
 - https://schema.org/version/latest/schemaorg-current-http.rdf
 - http://edamontology.org/EDAM_1.23.owl
