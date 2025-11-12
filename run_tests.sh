#!/bin/bash
# Run GUT tests from command line
# Usage: ./run_tests.sh [test_file_or_directory]

if [ -z "$1" ]; then
    # Run all tests
    godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit,res://tests/integration,res://tests/system
else
    # Run specific test file or directory
    godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir="$1"
fi
