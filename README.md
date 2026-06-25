# 🌅 Animasi Terbit Terbenam (Automatic Sunrise/Sunset Video Generator)

An automated Windows batch utility designed for **Stasiun Geofisika Alor** to extract sunrise and sunset data, overlay it onto location-specific templates, and compile the results into an animated infographic video.

---

## 🚀 Features

* [cite_start]**Auto-Dependency Management:** Checks for and automatically installs missing tools (`ImageMagick` and `FFmpeg`) using Windows Package Manager (`winget`).
* [cite_start]**Dynamic Pathing:** Smart-scans installation directories to execute tools without relying on rigid global system environment `%PATH%` variables[cite: 4, 5].
* [cite_start]**Automated Data Extraction:** Seamlessly extracts precise sunrise/sunset timings from multi-location MICA data spreadsheets (`.csv`)[cite: 7, 10, 11].
* [cite_start]**BOM & Quote Cleanup:** Smart data formatting cleans up hidden Byte Order Marks (BOM) and unwanted formatting artifacts before rendering[cite: 11, 17].
* [cite_start]**Localization:** Automatically computes a rolling 7-day calendar view formatted elegantly in Indonesian (`id-ID`)[cite: 13].
* [cite_start]**Context-Aware Styling:** Dynamically alternates between video assets (`base_ganjil` / `base_genap`) depending on whether the target month is odd or even[cite: 13, 14].
* [cite_start]**Hardware Acceleration Ready:** Built-in dual-pipeline script supports both universal CPU (`libx264`) and Nvidia GPU-accelerated encoding (`h264_nvenc`)[cite: 48, 49].

---

## 📂 Project Structure

Before running the script, organize your repository directory as follows:

```text
├── Animasi_Terbit_Terbenam.bat   # Main executable script
├── Assets/                       # Video templates (base_ganjil.mp4, base_genap.mp4)
├── Config/                       # Configuration assets
│   └── filters.txt               # Complex FFmpeg mapping instructions
├── Fonts/                        # Typography files
│   ├── Poppins-Regular.ttf       # Standard text font
│   └── Poppins-Bold.ttf          # Header text font
├── Source/                       # Input MICA data files
│   ├── Kabir.csv
│   ├── Kalabahi.csv
│   ├── Larantuka.csv
│   ├── Lewoleba.csv
│   └── Maritaing.csv
└── Output/                       # Processing area and final video destination
```
## 🛠️ Prerequisites
The script will attempt to install these automatically via winget if missing:  
* ImageMagick (For dynamic typography rendering onto transparent canvases)   
* Gyan FFmpeg (For high-fidelity video timeline merging)   

## 💻 How to Use
1. Prepare Data: Place your updated location CSV files inside the Source/ directory.
2. Run: Double-click Animasi_Terbit_Terbenam.bat.
3. Input Date: When prompted, enter your targeted calendar starting query in the exact format shown: Mar,09.
4. Export: The program will generate intermediate data layouts, render text maps, compile frame tracks, and export the finished video directly into the Output/ folder.  

## ⚙️ Hardware Acceleration (Optional)
If your machine utilizes an NVIDIA GeForce GTX/RTX GPU, you can dramatically speed up compilation by enabling NVENC encoding:  
1. Open Animasi_Terbit_Terbenam.bat in a text editor.
2. Locate the :: --- V. Merge it All in one video --- section.
3. Uncomment the NVIDIA CUDA pipeline execution string (!FFMPEG_CMD! -y -hwaccel cuda ...).
4. Comment out (add :: ahead of) the universal CPU line (!FFMPEG_CMD! -y %BASE% ...).  

## 📝 Authors & Acknowledgments
- AI Architecture: Designed and adapted by Gemini 3.
- Assembly & Optimization: Maintained by rhh for the operational workflow enhancement of Stasiun Geofisika Alor.  
