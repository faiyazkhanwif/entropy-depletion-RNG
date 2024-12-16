# Clean performance metrics csv
# Python script for processing the file, separating columns, and saving as a new CSV file.

import pandas as pd

# File path for the input and output files
input_file = 'data/04. Fedora 40 - Haveged - 3/performance_metrics.csv'
output_file = 'data/04. Fedora 40 - Haveged - 3/performance_metrics_cleaned.csv'

# Read the file, using whitespace as the delimiter to separate columns
data = pd.read_csv(input_file, delim_whitespace=True)

# Save the cleaned data to a new CSV file
data.to_csv(output_file, index=False)

# Display the first few rows of the cleaned data to confirm the structure
data.head(), output_file
