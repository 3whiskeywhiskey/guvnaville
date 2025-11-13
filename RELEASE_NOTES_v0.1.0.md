# Guvnaville v0.1.0 - MVP Release Notes

**Release Date**: November 13, 2025
**Version**: 0.1.0 (Minimum Viable Product)
**Status**: Initial Public Release

---

## Welcome to Guvnaville!

We're excited to present the first playable release of **Guvnaville**, a post-apocalyptic turn-based strategy game. This MVP release represents months of development and includes all core systems needed for a complete gameplay experience.

Lead your faction to survive and thrive in the ruins of a once-great city. Scavenge resources, build units, develop your culture, and compete with AI opponents for dominance!

---

## What's Included in v0.1.0

### Complete Gameplay Experience

✅ **Fully Playable Game**
- Turn-based strategy gameplay
- 4 victory conditions to pursue
- Dynamic procedurally generated maps
- 50+ unique events with meaningful choices
- Complete tutorial for new players

✅ **Strategic Depth**
- 5 unit types with distinct roles
- 7 building types for your faction
- 10 resources to manage
- 4-branch culture tree (30+ upgrades)
- 5 AI personalities to compete against

✅ **Polished User Experience**
- Interactive tutorial system
- Comprehensive in-game help (F1)
- Tooltips on all UI elements
- Keyboard shortcuts for efficiency
- Visual feedback and animations
- Complete documentation

---

## System Requirements

### Minimum Requirements

- **OS**: Windows 10, macOS 10.15, or Linux (Ubuntu 20.04+)
- **Processor**: Dual-core 2.0 GHz
- **Memory**: 2 GB RAM
- **Graphics**: OpenGL 3.3 compatible
- **Storage**: 500 MB available space

### Recommended Requirements

- **OS**: Windows 11, macOS 12+, or Linux (Ubuntu 22.04+)
- **Processor**: Quad-core 2.5 GHz
- **Memory**: 4 GB RAM
- **Graphics**: OpenGL 4.0 compatible
- **Storage**: 1 GB available space

---

## Installation Instructions

### Windows

1. Download `Guvnaville-v0.1.0-Windows.zip`
2. Extract the archive to your desired location
3. Run `Guvnaville.exe`
4. If Windows SmartScreen appears, click "More info" then "Run anyway"

### macOS

1. Download `Guvnaville-v0.1.0-macOS.zip`
2. Extract the archive
3. Move `Guvnaville.app` to your Applications folder
4. Right-click and select "Open" (first time only due to Gatekeeper)
5. Click "Open" in the security dialog

### Linux

1. Download `Guvnaville-v0.1.0-Linux.tar.gz`
2. Extract: `tar -xzf Guvnaville-v0.1.0-Linux.tar.gz`
3. Make executable: `chmod +x Guvnaville.x86_64`
4. Run: `./Guvnaville.x86_64`

---

## Getting Started

### First Launch

1. **Tutorial**: The game will offer to start the tutorial on first launch
   - **Recommended**: Follow the tutorial to learn game mechanics
   - **Skip**: Can be skipped and replayed later from main menu

2. **Documentation**: Check these resources:
   - **Quick Start Guide**: `docs/QUICK_START.md` - 5-minute guide
   - **User Manual**: `docs/USER_MANUAL.md` - Complete game guide
   - **In-Game Help**: Press F1 anytime during play

3. **Controls**: Essential keyboard shortcuts:
   - **Space/Enter**: End turn
   - **F1**: Help
   - **F5**: Quick save
   - **F9**: Quick load
   - **ESC**: Menu

### Your First Game

**Recommended Settings for First Game:**
- Difficulty: Easy
- Map Size: Normal
- AI Opponents: 2-3

**First 10 Turns Goal:**
- Scavenge 5+ locations for resources
- Build 2 additional units
- Construct your first building
- Explore 30% of the map
- Maintain food and water supplies

---

## Key Features

### Gameplay

**Core Mechanics**
- **Turn-Based Strategy**: Plan carefully, execute precisely
- **Resource Management**: Balance 10 different resource types
- **Unit System**: 5 specialized unit types (Scavenger, Soldier, Builder, Trader, Scout)
- **Building System**: 7 building types to develop your faction
- **Combat**: Tactical combat with terrain bonuses
- **Trading**: Exchange resources with AI factions

**Progression**
- **Culture System**: 4 distinct development branches
  - Military: Combat bonuses and advanced units
  - Economic: Resource gathering and trade benefits
  - Technology: Advanced buildings and equipment
  - Survival: Population growth and resilience
- **Population**: Grow and maintain your faction's people
- **Territory**: Capture and control strategic locations

**Victory Conditions**
1. **Domination**: Eliminate all enemy factions
2. **Economic**: Accumulate the most resources by turn 100
3. **Cultural**: Complete an entire culture branch
4. **Survival**: Last faction standing by turn 150

### AI Opponents

**5 Distinct Personalities:**
- **Aggressive**: Attacks frequently, expands rapidly
- **Defensive**: Builds strong bases, rarely attacks
- **Economic**: Focuses on resources and trade
- **Balanced**: Adapts to situations
- **Diplomatic**: Seeks alliances and cooperation

**4 Difficulty Levels:**
- **Easy**: Perfect for learning (AI makes mistakes)
- **Normal**: Balanced challenge (recommended)
- **Hard**: Smart AI with resource bonuses
- **Expert**: Optimal AI play with significant bonuses

### Events System

**50+ Unique Events:**
- **Resource Events**: Discoveries, shortages, opportunities
- **Combat Events**: Raids, ambushes, skirmishes
- **Social Events**: Refugees, disputes, morale issues
- **Environmental Events**: Storms, disasters, contamination

**Event Features:**
- Meaningful choices with consequences
- Event chains that span multiple turns
- Culture-based unique options
- Random yet balanced occurrence

### User Experience

**Tutorial System:**
- 10-step interactive tutorial
- Highlights relevant UI elements
- Can be skipped or replayed
- Pauses game for learning

**Help System:**
- Press F1 for comprehensive help
- 8 topic tabs covering all game aspects
- Searchable content
- Always accessible

**Tooltips:**
- Every button explained
- Resource information on hover
- Keyboard shortcuts shown
- Context-sensitive help

**Visual Polish:**
- Button hover effects
- Smooth transitions
- Animation feedback
- Clear visual indicators

---

## Documentation

### Player Resources

- **[User Manual](docs/USER_MANUAL.md)** (50+ pages)
  - Complete gameplay guide
  - All mechanics explained
  - Tips and strategies
  - Troubleshooting

- **[Quick Start Guide](docs/QUICK_START.md)**
  - 5-minute getting started
  - First 10 turns walkthrough
  - Essential controls
  - Common mistakes to avoid

- **[Changelog](CHANGELOG.md)**
  - Complete version history
  - All features listed
  - Future roadmap

### Developer Resources

- **[Technical Architecture](docs/TECHNICAL_ARCHITECTURE.md)**
  - System design
  - Code organization
  - API documentation

- **[Implementation Reports](docs/)**
  - Phase 1-4 completion reports
  - System interface specs
  - Architectural Decision Records (ADRs)

---

## Known Issues & Limitations

### Known Issues

**Minor Bugs:**
- Minimap may occasionally not update immediately (visual only)
- Some event text may extend beyond dialog in rare cases
- Tooltip positioning may be suboptimal on very small screens

**Workarounds:**
- Toggle minimap (click) to force refresh
- Resize window if text is clipped
- Adjust window size for better tooltip display

**Note**: None of these issues are game-breaking. All core functionality works as expected.

### Limitations

**Content:**
- Limited event pool (50+ events, more planned for v0.2.0)
- Single map biome (urban ruins)
- Basic AI diplomacy (will be expanded)

**Features:**
- No multiplayer support yet (planned for v0.2.0)
- No unit experience/leveling (planned for v0.2.0)
- No faction customization at start (planned for v0.2.0)
- No mod support yet (planned for v0.3.0)

**Polish:**
- Some placeholder art assets
- Limited audio (music/SFX planned for v0.2.0)
- Basic animations (will be enhanced)

**Balance:**
- Game balance is initial pass
- Some strategies may be stronger than others
- Will be refined based on community feedback

---

## Performance Notes

### Optimization

The game is optimized to run smoothly on minimum spec hardware:

- **Target**: 60 FPS on minimum specs
- **Map Generation**: <1 second for normal maps
- **Turn Processing**: <100ms with 4 AI opponents
- **Save/Load**: <2 seconds for full game state
- **Memory**: <500 MB typical usage

### Performance Tips

**If you experience slowdown:**
1. Close background applications
2. Update graphics drivers
3. Lower screen resolution if needed
4. Check system meets minimum requirements

**Reporting Performance Issues:**
- Include system specifications
- Note when slowdown occurs (turns, events, etc.)
- Attach save file if relevant

---

## Troubleshooting

### Common Issues

**Game Won't Start**
- Verify system meets minimum requirements
- Update graphics drivers
- Run as administrator (Windows)
- Check for antivirus blocking

**Graphics Issues**
- Update graphics drivers
- Try windowed mode
- Verify OpenGL 3.3+ support

**Save Games Not Loading**
- Ensure save files in correct location
- Check file not corrupted
- Try loading from main menu

**Performance Issues**
- Close background apps
- Lower graphics settings if available
- Reduce window size

### Save File Locations

**Windows**: `%APPDATA%/Godot/app_userdata/Guvnaville/saves/`
**macOS**: `~/Library/Application Support/Godot/app_userdata/Guvnaville/saves/`
**Linux**: `~/.local/share/godot/app_userdata/Guvnaville/saves/`

### Getting Help

**In-Game**: Press F1 for help
**Documentation**: See `docs/USER_MANUAL.md`
**Bug Reports**: See "Reporting Bugs" section below

---

## Reporting Bugs

We appreciate bug reports! Help us improve Guvnaville.

### Before Reporting

1. Check if it's a known issue (see above)
2. Try reproducing the bug
3. Check if others reported it (GitHub Issues)

### How to Report

**Include:**
- Detailed description of the bug
- Steps to reproduce
- Expected vs. actual behavior
- Screenshots (if relevant)
- Save file (if relevant)
- System information

**Where to Report:**
- **GitHub Issues**: [Your GitHub Repo]/issues
- **Tag**: Use "bug" label
- **Priority**: Critical, High, Medium, Low

**Save Files:**
When reporting bugs, include save file if possible. Compress with zip/tar before uploading.

---

## Community & Support

### Get Involved

**Discord** (if available): Join for discussions and help
**GitHub**: [Your Repo URL]
**Wiki** (if available): Community-maintained game wiki

### Feedback Welcome

We want to hear from you!

- **Bug Reports**: GitHub Issues
- **Feature Requests**: GitHub Discussions
- **Balance Feedback**: What's too strong/weak?
- **General Feedback**: What do you like/dislike?

### Contributing

Interested in contributing?

- **Code**: See CONTRIBUTING.md (if available)
- **Content**: Event ideas, balance suggestions
- **Documentation**: Improve guides and help
- **Testing**: Playtest and report findings

---

## Future Plans

### Version 0.2.0 (Next Release)

**Target**: Q1 2026

**Planned Features:**
- Multiplayer support (hot-seat mode)
- Faction customization at game start
- Additional map types (desert, forest, mountain)
- More events (targeting 100+ total)
- Enhanced AI diplomacy
- Unit experience and leveling
- Additional building types
- Audio and music

### Version 0.3.0

**Target**: Q2 2026

**Planned Features:**
- Online multiplayer
- Campaign mode with story
- Advanced mod support
- Map editor
- Replay system
- Statistics and analytics

### Version 1.0.0 (Full Release)

**Target**: Late 2026

**Planned Features:**
- Complete content (200+ events)
- Polished art and audio
- Multiple campaigns
- Comprehensive mod tools
- Achievements
- Leaderboards
- Steam integration (if approved)

**Note**: Roadmap subject to change based on community feedback and development progress.

---

## Credits

### Development

**Game Design & Programming**: [Your Name/Team]
**Testing**: [Testers]
**Documentation**: [Doc Writers]

### Special Thanks

- **Godot Engine Team**: For the amazing open-source engine
- **GUT Framework**: For comprehensive testing tools
- **Community**: For feedback and support
- **You**: For playing Guvnaville!

### Technology

- **Engine**: Godot 4.2.2
- **Language**: GDScript
- **Testing**: GUT (Godot Unit Test)
- **CI/CD**: GitHub Actions
- **Version Control**: Git

---

## License

[Your License Here - e.g., MIT, GPL, etc.]

See LICENSE file for full license text.

---

## Final Notes

### Thank You!

Thank you for being part of the Guvnaville journey! This MVP release represents the foundation of what we hope will become a deep and engaging strategy game.

Your feedback is invaluable. Whether you love something, hate something, or have ideas for improvement, we want to hear about it.

### Stay Updated

- **GitHub**: Watch the repository for updates
- **Discord**: Join for real-time discussion (if available)
- **Releases**: Check GitHub Releases for new versions

### Have Fun!

Most importantly: **Have fun!** Guvnaville is meant to be challenging but enjoyable. Experiment with different strategies, make tough decisions, and see if you can lead your faction to victory.

Remember:
- Press **F1** for help anytime
- **F5** to save your progress
- Take your time - it's turn-based!

**Good luck, Guvna! Your people are counting on you.**

---

**Version**: 0.1.0
**Release Date**: November 13, 2025
**Status**: MVP - Fully Playable

*Survive. Thrive. Conquer.*
