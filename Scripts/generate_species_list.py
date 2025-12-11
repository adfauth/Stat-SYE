from birdnet import predict_species_at_location_and_time
import pandas as pd

# Define your location and time
latitude = 44.5956  
longitude = -75.1691 
week = 15 

# Predict species occurrence
predictions = predict_species_at_location_and_time(latitude, longitude, week=week)

# The result is a dictionary mapping species names to confidence scores.
# You can sort it to see the most probable species first.
sorted_predictions = sorted(predictions.items(), key=lambda item: item[1], reverse=True)

# Create a dataframe:
df = pd.DataFrame(sorted_predictions, columns=['Species', 'Probability'])

# The full predictions dictionary can be used to filter predictions
# when analyzing audio files with other BirdNET functions.
# Write a csv file to use in analysis:
df.to_csv('generated_species.csv', index=False)
