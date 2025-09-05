from pathlib import Path

from birdnet import SpeciesPredictions, predict_species_within_audio_file
import time

import pandas as pd

folder_path = Path("A001_SD001_toy")
audio_files = list(folder_path.glob("*.WAV"))
audio_files

all_dfs = [] ## storage

for audio_path in audio_files:
    print(f"Processing {audio_path.name}...")

    start = time.perf_counter()

    # Run the prediction
    predictions = SpeciesPredictions(
        predict_species_within_audio_file(
            audio_path,
            min_confidence=0.4,
            chunk_overlap_s=0.0
        )
    )

    # Convert predictions to a DataFrame
    df = pd.DataFrame([
        {'start': start_t, 'end': end_t, **species_probs}
        for (start_t, end_t), species_probs in predictions.items()
    ])

    # Add audio file identifier
    df['file'] = audio_path.name 

    end = time.perf_counter()
    print(f"Finished {audio_path.name} in {end - start:.2f} seconds")

    all_dfs.append(df)

all_dfs
combined_df = pd.concat(all_dfs, ignore_index=True)
combined_df.to_csv("output.csv", index=False)