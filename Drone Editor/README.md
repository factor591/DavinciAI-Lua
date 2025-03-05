# Drone Editor for DaVinci Resolve

Drone Editor is a specialized automation tool designed to streamline the editing process for drone footage within DaVinci Resolve. This Lua-based framework provides a comprehensive set of tools for automated scene detection, color grading, audio enhancement, and project management specifically optimized for aerial videos.

## Features

- **Native Resolve Integration**: Built using DaVinci Resolve's official Lua API for reliable performance
- **Automated Scene Detection**: Intelligent detection of scene changes in drone footage
- **Specialized Color Grading**: Presets and LUTs specifically designed for aerial footage
- **Audio Enhancement**: Reduce wind noise and improve audio quality in drone recordings
- **Timeline Automation**: Create professional edits with a single click
- **Fusion UI**: Custom interface built with Fusion's native UI framework
- **Project Management**: Save, load, and manage your drone editing projects
- **Cross-Platform**: Works on Windows, macOS, and Linux

## Requirements

- **DaVinci Resolve 18.x or 19.x**
- **Lua 5.1** (included with DaVinci Resolve)
- No additional dependencies required

## Installation

### Automatic Installation (Recommended)

1. Run the included `install.lua` script with Lua 5.1:
   ```
   lua install.lua
   ```
   This will automatically install Drone Editor to the correct DaVinci Resolve Scripts directory for your operating system.

### Manual Installation

1. Locate your DaVinci Resolve Scripts directory:
   - **Windows**: `%APPDATA%\Blackmagic Design\DaVinci Resolve\Support\Scripts`
   - **macOS**: `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Support/Scripts`
   - **Linux**: `~/.local/share/DaVinciResolve/Support/Scripts`

2. Create a folder named `Drone Editor` in the Scripts directory

3. Copy all project files to the `Drone Editor` folder, maintaining the directory structure

4. Copy `DroneEditor.lua` directly to the Scripts directory (not in the `Drone Editor` subfolder)

## Usage

### Launching Drone Editor

1. Open DaVinci Resolve
2. Go to the **Workspace** menu
3. Select **Scripts**
4. Click on **DroneEditor**

The Drone Editor interface will appear, providing access to all features.

### Core Workflows

#### Automatic Edit

1. Import your drone footage using the **Import Media** button
2. Click **Auto Edit** to create a complete edit with scene detection, transitions, color grading, and audio enhancement
3. Fine-tune the results as needed

#### Manual Workflow

1. Import your drone footage
2. Use **Detect Scenes** to analyze footage and create scene-based segments
3. Apply color grading using the **Color Grading** panel
4. Enhance audio with the AI audio tools
5. Save your project with **Project Settings**

## Features in Detail

### Scene Detection

The scene detection algorithm analyzes drone footage for visual changes such as:
- Camera movement transitions
- Significant changes in scenery
- Start/end of cinematic movements
- Cutting points for optimal pacing

### Color Grading

Specialized color presets for drone footage:
- **Drone Aerial**: Enhances sky blues and landscape greens
- **Cinematic**: Film-like color treatment for professional look
- **Vintage**: Stylized look with subtle color shifts
- **Natural**: Clean, accurate color reproduction

### Audio Enhancement

- **Wind Noise Reduction**: Specialized filtering for drone propeller and wind noise
- **Auto Volume Balancing**: Even out audio levels
- **EQ Adjustments**: Optimize frequency response for clearer sound

### Project Management

- Save your editing projects in the `.droneproj` format
- Includes timeline information, color grading settings, and clip organization
- Cross-platform project format works across Windows, macOS, and Linux

## Advanced Usage

### Console Mode

Drone Editor can be run in console mode for script-based automation:
- Run `main.lua` with the `--console` flag
- Access all functionality through Lua commands
- Use `help()` to see available commands

### Custom LUTs

Add your own LUTs to DaVinci Resolve's LUT directory:
- **Windows**: `%APPDATA%\Blackmagic Design\DaVinci Resolve\Support\LUT`
- **macOS**: `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/LUT`
- **Linux**: `~/.local/share/DaVinciResolve/LUT`

Then update the `settings.lua` file to reference your custom LUTs.

## Project Structure

- **lib/**: Core library modules
  - `fusion_ui.lua`: Fusion-based UI implementation
  - `fusion_dialogs.lua`: Native Fusion dialog system
  - `resolve_connection.lua`: DaVinci Resolve API connection management
  - `timeline.lua`: Timeline manipulation functions
  - `mediapool.lua`: Media management operations
  - `color.lua`: Color grading functionality
  - `fusion.lua`: Fusion effects automation
  - `project.lua`: Project management functionality
  - `ui.lua`: Fallback UI implementation
- **utils/**: Utility modules
  - `logging.lua`: Logging system
  - `ai_simulation.lua`: AI simulation for various features
  - `ai_bridge.lua`: Framework for connecting to real AI services
- **config/**: Configuration files
  - `settings.lua`: Application settings
  - `ai_settings.json`: AI configuration parameters
- **Main Files**:
  - `DroneEditor.lua`: Entry point for DaVinci Resolve Scripts menu
  - `main.lua`: Main application logic and initialization
  - `bootstrap.lua`: Environment setup and path configuration
  - `check_environment.lua`: Validation tool for troubleshooting

## Troubleshooting

### Common Issues

1. **UI doesn't appear**:
   - Drone Editor will automatically fallback to console mode if UI initialization fails
   - Check the log files in the `logs` directory for error details

2. **Cannot connect to DaVinci Resolve**:
   - Ensure DaVinci Resolve is running
   - Check if you're using a supported version (18.x or 19.x)
   - Run `check_environment.lua` for detailed diagnostics

3. **Missing modules**:
   - Verify all files are in the correct directories
   - Check path settings in `bootstrap.lua`

### Log Files

Log files are stored in:
- **Windows**: `%USERPROFILE%\Documents\DroneEditor\logs`
- **macOS/Linux**: `~/Documents/DroneEditor/logs`

## Development

### Environment Setup

1. Clone the repository
2. Run `check_environment.lua` to verify your development environment
3. Use the launcher scripts to test in different modes:
   - `launcher.bat` (Windows) or `launcher.sh` (macOS/Linux)

### Module Development

When creating new modules:
1. Follow the modular design pattern with explicit dependency requirements
2. Use `pcall` for error handling
3. Add detailed logging
4. Consider version compatibility with different Resolve releases

## License

Copyright © 2025. All rights reserved.

## Acknowledgments

- Blackmagic Design for DaVinci Resolve and its Lua API
- The Lua community for language resources

## Contact

For support, feature requests, or bug reports, please contact the developers.