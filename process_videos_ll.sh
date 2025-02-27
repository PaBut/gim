#!/bin/bash

mkdir -p logs
mkdir -p data/ZeroMatch/pseudo
mkdir -p data/ZeroMatch/video_1080p

function select_gpu() {
  while true; do
    readarray -t total_memory < <(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
    readarray -t memory_free < <(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits)
    for i in "${!memory_free[@]}"; do
      local free_percent=$(awk -v free="${memory_free[$i]}" -v total="${total_memory[$i]}" 'BEGIN{print (free/total)*100}')
      if (( $(awk -v fp="$free_percent" -v tp=95 'BEGIN{print (fp >= tp)}') )); then
        echo $i
        return
      fi
    done

    sleep 30
  done
}

for file in ./data/ZeroMatch/video_1080p/*.mp4; do
  VIDEO_ID=$(basename "$file" .mp4)
  # echo $file . $VIDEO_ID \n

  # output_file="./data/ZeroMatch/video_1080p/${VIDEO_ID}.mp4"
  # if [ ! -f "$output_file" ]; then
  #   yt-dlp -f 'bv*[ext=mp4][height=1080]+ba[ext=m4a]/b[ext=mp4][height=1080]' -S "height, fps" "https://www.youtube.com/watch?v=$VIDEO_ID" --no-audio -o "$output_file"
  # else
  #   echo "Video file $output_file already exists. Skipping download."
  # fi

  if ! [[ "$VIDEO_ID" =~ ^[0-9]+$ ]]; then
    echo "Skipping: $VIDEO_ID (not a numeric name)"
    continue  # Skip this file and move to the next one
  fi

  printf "|%s|%s|%s|%s|%s|%s|\n" "======================" "==============" "============" "======" "========" "====="
  printf "| %-20s | %-12s | %-10s | %-4s | %-6s | %-3s |\n" "Timestamp" "Video ID" "Method" "Skip" "Resize" "GPU"
  printf "|%s|%s|%s|%s|%s|%s|\n" "----------------------" "--------------" "------------" "------" "--------" "-----"

  for skip in 0 1 2
  do
    for method in GIM_DKM GIM_LOFTR GIM_GLUE SIFT
    do

      gpu=$(select_gpu)
      logstamp=$(date +'%Y%m%d_%H%M%S')
      timestamp=$(date +"%Y-%m-%d %H:%M:%S")
      printf "| %-20s | %-12s | %-10s | %-4s | %-6s | %-3s |\n" "$timestamp" "$VIDEO_ID" "$method" "$skip" "No" "$gpu"
      python3 video_preprocessor.py --gpu=$gpu --scene_name="$VIDEO_ID" --method=$method --skip=$skip > "logs/${VIDEO_ID}_${method}_skip${skip}_${logstamp}.log" 2>&1 &
      sleep 30
    done
  done

  for skip in 0 1 2
  do
    for method in GIM_DKM GIM_LOFTR GIM_GLUE SIFT
    do
      gpu=$(select_gpu)
      logstamp=$(date +'%Y%m%d_%H%M%S')
      timestamp=$(date +"%Y-%m-%d %H:%M:%S")
      printf "| %-20s | %-12s | %-10s | %-4s | %-6s | %-3s |\n" "$timestamp" "$VIDEO_ID" "$method" "$skip" "Yes" "$gpu"
      python3 video_preprocessor.py --gpu=$gpu --scene_name="$VIDEO_ID" --method=$method --skip=$skip --resize > "logs/${VIDEO_ID}_${method}_skip${skip}_resize_${logstamp}.log" 2>&1 &
      sleep 30
    done
  done

done
