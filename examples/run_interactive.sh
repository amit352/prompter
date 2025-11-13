#!/bin/bash
# Interactive demo script

echo "========================================================================"
echo "  INTERACTIVE PROCESSOR DEMO"
echo "========================================================================"
echo ""
echo "This will run Prompter with the processor feature."
echo "You'll select a release version, then see dynamically filtered flags."
echo ""
echo "========================================================================"
echo ""

# Run the demo with simulated input
# First select option 2 (3.1.5.3), then select flags 1,3,5 (using space to select)
ruby -r ./examples/processors/feature_flag_processor.rb \
     -I./lib \
     ./bin/prompter \
     examples/simple_demo.yml \
     examples/demo_output.yml

echo ""
echo "========================================================================"
echo "Demo completed!"
echo ""
echo "Check examples/demo_output.yml for the generated configuration."
echo "========================================================================"
